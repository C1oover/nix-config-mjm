use core::str;
use std::{
    cmp::Ordering,
    collections::{HashMap, HashSet},
    ffi::OsStr,
    process::Command,
};

use anyhow::{bail, format_err, Result};
use clap::{Args, Parser, Subcommand};
use serde::{Deserialize, Serialize};

#[derive(Parser)]
#[command(version, about)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Diff(DiffArgs),
    RebootCheck(RebootCheckArgs),
    Aggregate(AggregateArgs),
}

#[derive(Args)]
struct DiffArgs {
    left: std::path::PathBuf,
    right: std::path::PathBuf,
}

#[derive(Args)]
struct RebootCheckArgs {
    path: std::path::PathBuf,
}

#[derive(Args)]
struct AggregateArgs {
    results: Vec<std::path::PathBuf>,
}

fn main() {
    let args = Cli::parse();

    match args.command {
        Commands::Diff(diff_args) => {
            let result = run_diff(&diff_args.left, &diff_args.right).unwrap();
            serde_json::to_writer_pretty(std::io::stdout(), &result).unwrap();
        }
        Commands::RebootCheck(reboot_check_args) => {
            let result = run_reboot_check(&reboot_check_args.path).unwrap();
            serde_json::to_writer_pretty(std::io::stdout(), &result).unwrap();
        }
        Commands::Aggregate(aggregate_args) => {
            let result = run_aggregate(aggregate_args.results).unwrap();
            serde_json::to_writer_pretty(std::io::stdout(), &result).unwrap();
        }
    }
}

#[derive(Deserialize, Serialize, Debug)]
struct DiffResult {
    left: String,
    right: String,
    version_changes: Vec<VersionChange>,
    added_packages: Vec<VersionChange>,
    removed_packages: Vec<VersionChange>,
    reboot_packages: Vec<VersionChange>,
}

#[derive(Deserialize, Serialize, Debug)]
struct VersionChange {
    pname: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    old_versions: Option<Vec<String>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    new_versions: Option<Vec<String>>,
}

fn run_diff(left: &std::path::Path, right: &std::path::Path) -> Result<DiffResult> {
    if !left.try_exists()? {
        bail!("left path {} does not exist", left.display())
    }

    if !right.try_exists()? {
        bail!("right path {} does not exist", right.display())
    }

    let left_canonical = left.canonicalize()?;
    let right_canonical = right.canonicalize()?;
    let boot_canonical = std::path::Path::new("/run/booted-system").canonicalize()?;

    let left_closure = PackageSet::from_closure(&left_canonical)?;
    let right_closure = PackageSet::from_closure(&right_canonical)?;
    let boot_closure = PackageSet::from_closure(&boot_canonical)?;

    let closure_pair = PackageSetPair::new(&left_closure, &right_closure);
    let boot_pair = PackageSetPair::new(&boot_closure, &right_closure);

    Ok(DiffResult {
        left: left_canonical.to_string_lossy().to_string(),
        right: right_canonical.to_string_lossy().to_string(),
        version_changes: closure_pair.get_version_changes(),
        added_packages: closure_pair.get_added_packages(),
        removed_packages: closure_pair.get_removed_packages(),
        reboot_packages: boot_pair.get_changes(["linux", "systemd"]),
    })
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum VersionChunk {
    Int(u64),
    Str(String),
}

impl Ord for VersionChunk {
    fn cmp(&self, other: &Self) -> Ordering {
        self.partial_cmp(other).unwrap()
    }
}

impl PartialOrd for VersionChunk {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(match (self, other) {
            (left, right) if left == right => Ordering::Equal,
            (VersionChunk::Int(left), VersionChunk::Int(right)) => left.cmp(right),
            (VersionChunk::Str(ref val), VersionChunk::Int(_)) if val == "" => Ordering::Less,
            (VersionChunk::Str(ref val), _) if val == "pre" => Ordering::Less,
            (VersionChunk::Int(_), VersionChunk::Str(ref val)) if val == "" => Ordering::Greater,
            (_, VersionChunk::Str(ref val)) if val == "pre" => Ordering::Greater,
            (VersionChunk::Int(_), VersionChunk::Str(_)) => Ordering::Greater,
            (VersionChunk::Str(_), VersionChunk::Int(_)) => Ordering::Less,
            (VersionChunk::Str(ref left), VersionChunk::Str(ref right)) => left.cmp(right),
        })
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
struct Version {
    text: String,
    chunks: Vec<VersionChunk>,
}

impl Version {
    fn new(text: &str) -> Self {
        let mut iter = text.chars().peekable();
        let mut chunks = Vec::new();
        while let Some(next) = iter.next() {
            if next.is_ascii_digit() {
                let mut chunk = String::new();
                chunk.push(next);

                while iter.peek().map_or(false, |c| c.is_ascii_digit()) {
                    chunk.push(iter.next().unwrap());
                }

                let val: u64 = chunk.parse().unwrap();
                chunks.push(VersionChunk::Int(val));
            } else if next.is_alphabetic() {
                let mut chunk = String::new();
                chunk.push(next);

                while iter.peek().map_or(false, |c| c.is_alphabetic()) {
                    chunk.push(iter.next().unwrap());
                }

                chunks.push(VersionChunk::Str(chunk));
            }
        }

        Self {
            text: text.to_string(),
            chunks,
        }
    }
}

#[derive(Debug, PartialEq, Eq)]
struct Package {
    pname: String,
    version: Version,
    store_path: std::path::PathBuf,
}

impl Package {
    fn from_store_path(path: &std::path::Path) -> Option<Self> {
        let basename = path.file_name()?.to_str()?;

        let chunks: Vec<&str> = basename.split('-').skip(1).collect();
        let (pname_chunks, version_chunks) = match chunks.iter().position(|chunk| {
            if let Some(c) = chunk.chars().nth(0) {
                c.is_digit(10)
            } else {
                false
            }
        }) {
            Some(pos) => chunks.split_at(pos),
            None => (&chunks[..], &[] as &[&str]),
        };

        let pname = pname_chunks.join("-");
        let version = version_chunks.join("-");

        Some(Package {
            pname,
            version: Version::new(&version),
            store_path: path.to_path_buf(),
        })
    }
}

#[derive(Debug)]
struct PackageSet {
    store_paths: Vec<std::path::PathBuf>,
    packages_by_pname: HashMap<String, Vec<Package>>,
}

impl PackageSet {
    fn new(packages: Vec<Package>, store_paths: Vec<std::path::PathBuf>) -> Self {
        let mut by_pname = HashMap::new();

        for p in packages {
            by_pname
                .entry(p.pname.clone())
                .or_insert_with(Vec::new)
                .push(p);
        }

        for (_pname, packages) in by_pname.iter_mut() {
            packages.sort_by_key(|p| p.version.clone());
        }

        PackageSet {
            store_paths,
            packages_by_pname: by_pname,
        }
    }

    fn from_store_paths(store_paths: Vec<std::path::PathBuf>) -> Result<Self> {
        let packages = store_paths
            .iter()
            .map(|path| -> Result<Package> {
                Ok(Package::from_store_path(path).ok_or(format_err!(
                    "could not get package info from store path {}",
                    path.display()
                ))?)
            })
            .collect::<Result<_>>()?;

        Ok(Self::new(packages, store_paths))
    }

    // fn from_direct_dependencies(path: &std::path::Path) -> Result<Self> {
    //     Self::from_nix_query(&[OsStr::new("--references"), path.as_os_str()])
    // }

    fn from_closure(path: &std::path::Path) -> Result<Self> {
        Self::from_nix_query(&[OsStr::new("--requisites"), path.as_os_str()])
    }

    fn from_nix_query(args: &[&OsStr]) -> Result<Self> {
        let output = Command::new("nix-store")
            .arg("--query")
            .args(args)
            .output()?
            .stdout;
        let output_str = str::from_utf8(&output)?;

        let paths = output_str
            .trim_end()
            .lines()
            .map(|line| line.into())
            .collect();

        Self::from_store_paths(paths)
    }

    // fn contains_pname(self: &Self, pname: &str) -> bool {
    //     self.packages_by_pname.contains_key(pname)
    // }

    fn all_pnames(self: &Self) -> Vec<String> {
        self.packages_by_pname.keys().cloned().collect()
    }

    // fn get_pname_packages(self: &Self, pname: &str) -> Option<&Vec<Package>> {
    //     self.packages_by_pname.get(pname)
    // }

    fn get_pname_versions(self: &Self, pname: &str) -> Option<Vec<Version>> {
        self.packages_by_pname
            .get(pname)
            .map(|packages| packages.iter().map(|p| p.version.clone()).collect())
    }

    fn get_pname_version_strings(self: &Self, pname: &str) -> Option<Vec<String>> {
        self.get_pname_versions(&pname)
            .map(|vs| vs.into_iter().map(|v| v.text).collect())
    }
}

struct PackageSetPair<'a> {
    left: &'a PackageSet,
    right: &'a PackageSet,
    changed_pnames: Vec<String>,
    added_pnames: Vec<String>,
    removed_pnames: Vec<String>,
}

impl<'a> PackageSetPair<'a> {
    fn new(left: &'a PackageSet, right: &'a PackageSet) -> PackageSetPair<'a> {
        let left_pnames = HashSet::<String>::from_iter(left.all_pnames());
        let right_pnames = HashSet::from_iter(right.all_pnames());

        let present_in_both = left_pnames.intersection(&right_pnames);

        let mut changed_pnames = Vec::new();
        for pname in present_in_both {
            if left.get_pname_versions(pname) != right.get_pname_versions(pname) {
                changed_pnames.push(pname.to_string());
            }
        }
        changed_pnames.sort();

        let mut added_pnames: Vec<String> =
            right_pnames.difference(&left_pnames).cloned().collect();
        added_pnames.sort();

        let mut removed_pnames: Vec<String> =
            left_pnames.difference(&right_pnames).cloned().collect();
        removed_pnames.sort();

        PackageSetPair {
            left,
            right,
            changed_pnames,
            added_pnames,
            removed_pnames,
        }
    }

    fn get_version_changes(&self) -> Vec<VersionChange> {
        self.get_changes(&self.changed_pnames)
    }

    fn get_added_packages(&self) -> Vec<VersionChange> {
        self.get_changes(&self.added_pnames)
    }

    fn get_removed_packages(&self) -> Vec<VersionChange> {
        self.get_changes(&self.removed_pnames)
    }

    fn get_changes(&self, pnames: impl IntoIterator<Item = impl AsRef<str>>) -> Vec<VersionChange> {
        pnames
            .into_iter()
            .filter_map(|pname| {
                let pname = pname.as_ref();
                let old_versions = self.left.get_pname_version_strings(&pname);
                let new_versions = self.right.get_pname_version_strings(&pname);

                if old_versions == new_versions {
                    None
                } else {
                    Some(VersionChange {
                        pname: pname.to_string(),
                        old_versions,
                        new_versions,
                    })
                }
            })
            .collect()
    }
}

#[derive(Serialize)]
struct AggregatedDiffResult {
    version_changes: Vec<AggregatedVersionChange>,
    added_packages: Vec<AggregatedVersionChange>,
    removed_packages: Vec<AggregatedVersionChange>,
    reboot_packages: Vec<AggregatedVersionChange>,
}

#[derive(Serialize)]
struct AggregatedVersionChange {
    pname: String,
    hosts: Vec<PerHostVersionChange>,
}

#[derive(Serialize)]
struct PerHostVersionChange {
    hostname: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    old_versions: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    new_versions: Option<Vec<String>>,
}

fn run_aggregate(results: Vec<std::path::PathBuf>) -> Result<AggregatedDiffResult> {
    let loaded_results = results
        .iter()
        .map(|path| -> Result<(String, DiffResult)> {
            let f = std::fs::File::open(path)?;
            let reader = std::io::BufReader::new(f);
            Ok((
                path.file_stem().unwrap().to_string_lossy().to_string(),
                serde_json::from_reader(reader)?,
            ))
        })
        .collect::<Result<Vec<_>>>()?;

    let mut version_changes_by_pname: HashMap<String, AggregatedVersionChange> = HashMap::new();
    let mut added_packages_by_pname: HashMap<String, AggregatedVersionChange> = HashMap::new();
    let mut removed_packages_by_pname: HashMap<String, AggregatedVersionChange> = HashMap::new();
    let mut reboot_packages_by_pname: HashMap<String, AggregatedVersionChange> = HashMap::new();

    for (hostname, result) in loaded_results {
        aggregate_host_changes(
            &mut version_changes_by_pname,
            &hostname,
            result.version_changes,
        );
        aggregate_host_changes(
            &mut added_packages_by_pname,
            &hostname,
            result.added_packages,
        );
        aggregate_host_changes(
            &mut removed_packages_by_pname,
            &hostname,
            result.removed_packages,
        );
        aggregate_host_changes(
            &mut reboot_packages_by_pname,
            &hostname,
            result.reboot_packages,
        );
    }

    Ok(AggregatedDiffResult {
        version_changes: get_sorted_aggregated_changes(version_changes_by_pname),
        added_packages: get_sorted_aggregated_changes(added_packages_by_pname),
        removed_packages: get_sorted_aggregated_changes(removed_packages_by_pname),
        reboot_packages: get_sorted_aggregated_changes(reboot_packages_by_pname),
    })
}

fn aggregate_host_changes(
    changes_by_pname: &mut HashMap<String, AggregatedVersionChange>,
    hostname: &str,
    changes: Vec<VersionChange>,
) {
    for vc in changes {
        changes_by_pname
            .entry(vc.pname)
            .or_insert_with_key(|pname| AggregatedVersionChange {
                pname: pname.clone(),
                hosts: Vec::new(),
            })
            .hosts
            .push(PerHostVersionChange {
                hostname: hostname.to_string(),
                old_versions: vc.old_versions,
                new_versions: vc.new_versions,
            })
    }
}

fn get_sorted_aggregated_changes(
    changes_by_pname: HashMap<String, AggregatedVersionChange>,
) -> Vec<AggregatedVersionChange> {
    let mut changes: Vec<_> = changes_by_pname.into_values().collect();
    changes.sort_by_key(|avc| avc.pname.clone());
    return changes;
}

#[derive(Serialize)]
struct RebootCheckResult {
    reboot_needed: bool,
}

fn run_reboot_check(path: &std::path::Path) -> Result<RebootCheckResult> {
    let boot_canonical = std::path::Path::new("/run/booted-system").canonicalize()?;
    let new_canonical = path.canonicalize()?;
    let boot_closure = PackageSet::from_closure(&boot_canonical)?;
    let new_closure = PackageSet::from_closure(&new_canonical)?;

    let closure_pair = PackageSetPair::new(&boot_closure, &new_closure);
    let reboot_packages = closure_pair.get_changes(["linux", "systemd"]);

    Ok(RebootCheckResult {
        reboot_needed: !reboot_packages.is_empty(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_chunk_sorting() {
        use Ordering::*;
        use VersionChunk::*;

        assert_eq!(
            Str(String::from("asdf")).cmp(&Str(String::from("asdf"))),
            Equal
        );
        assert_eq!(Int(2).cmp(&Int(2)), Equal);
        assert_eq!(Int(12).cmp(&Int(13)), Less);
        assert_eq!(Int(12).cmp(&Int(11)), Greater);
        assert_eq!(Str(String::from("")).cmp(&Int(24)), Less);
        assert_eq!(
            Str(String::from("pre")).cmp(&Str(String::from("asdf"))),
            Less
        );
        assert_eq!(Str(String::from("pre")).cmp(&Int(24)), Less);
        assert_eq!(Int(23).cmp(&Str(String::from(""))), Greater);
        assert_eq!(
            Str(String::from("asdf")).cmp(&Str(String::from("pre"))),
            Greater
        );
        assert_eq!(Int(7).cmp(&Str(String::from("pre"))), Greater);
        assert_eq!(Int(8).cmp(&Str(String::from("klwer"))), Greater);
        assert_eq!(Str(String::from("jkew")).cmp(&Int(1)), Less);
        assert_eq!(
            Str(String::from("abc")).cmp(&Str(String::from("abd"))),
            Less
        );
        assert_eq!(
            Str(String::from("abd")).cmp(&Str(String::from("abc"))),
            Greater
        );
    }

    #[test]
    fn version_parsing() {
        use VersionChunk::*;

        assert_eq!(
            Version::new("12.3.4"),
            Version {
                text: String::from("12.3.4"),
                chunks: vec![Int(12), Int(3), Int(4)]
            }
        );
        assert_eq!(
            Version::new("6.6.52-modules-shrunk"),
            Version {
                text: String::from("6.6.52-modules-shrunk"),
                chunks: vec![
                    Int(6),
                    Int(6),
                    Int(52),
                    Str(String::from("modules")),
                    Str(String::from("shrunk"))
                ]
            }
        );
        // this is kind of a whack way for this to parse
        assert_eq!(
            Version::new("24.11pre688350.e873268a358f"),
            Version {
                text: String::from("24.11pre688350.e873268a358f"),
                chunks: vec![
                    Int(24),
                    Int(11),
                    Str(String::from("pre")),
                    Int(688350),
                    Str(String::from("e")),
                    Int(873268),
                    Str(String::from("a")),
                    Int(358),
                    Str(String::from("f"))
                ]
            }
        );
    }

    #[test]
    fn package_from_store_path() {
        use std::path::{Path, PathBuf};

        assert_eq!(Package::from_store_path(Path::new("")), None);
        assert_eq!(Package::from_store_path(Path::new("/")), None);
        assert_eq!(
            Package::from_store_path(Path::new(
                "/nix/store/gmsnrmj9afqf1q0fksq6q0yxf4j5gz6f-source"
            )),
            Some(Package {
                pname: String::from("source"),
                version: Version::new(""),
                store_path: PathBuf::from("/nix/store/gmsnrmj9afqf1q0fksq6q0yxf4j5gz6f-source")
            })
        );
        assert_eq!(
            Package::from_store_path(Path::new(
                "/nix/store/y6dbsv4f9fap82877akbwbwmh7sg8vw9-linux-6.6.22-modules-shrunk"
            )),
            Some(Package {
                pname: String::from("linux"),
                version: Version::new("6.6.22-modules-shrunk"),
                store_path: PathBuf::from(
                    "/nix/store/y6dbsv4f9fap82877akbwbwmh7sg8vw9-linux-6.6.22-modules-shrunk"
                )
            })
        );
        assert_eq!(
            Package::from_store_path(Path::new(
                "/nix/store/7smdp6l51dl5242n9i4a394vriq4wmsx-nsncd-unstable-2024-01-16"
            )),
            Some(Package {
                pname: String::from("nsncd-unstable"),
                version: Version::new("2024-01-16"),
                store_path: PathBuf::from(
                    "/nix/store/7smdp6l51dl5242n9i4a394vriq4wmsx-nsncd-unstable-2024-01-16"
                )
            })
        );
        assert_eq!(
            Package::from_store_path(Path::new(
                "/nix/store/ci4y46j5xdjgrl8cyn6f46kz5h2lzxvx-publicsuffix-list-0-unstable-2024-01-07"
            )),
            Some(Package {
                pname: String::from("publicsuffix-list"),
                version: Version::new("0-unstable-2024-01-07"),
                store_path: PathBuf::from(
                    "/nix/store/ci4y46j5xdjgrl8cyn6f46kz5h2lzxvx-publicsuffix-list-0-unstable-2024-01-07"
                )
            })
        );
    }
}
