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

#[derive(Deserialize, Serialize, Debug, Clone)]
struct DiffResult {
    left: String,
    right: String,
    version_changes: Vec<VersionChange>,
    added_packages: Vec<VersionChange>,
    removed_packages: Vec<VersionChange>,
    reboot_packages: Vec<VersionChange>,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq, Clone)]
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
        reboot_packages: boot_pair.get_simple_changes(["linux", "systemd"]),
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
                c.is_digit(10) || (chunk.len() >= 7 && chunk.chars().all(|c| c.is_ascii_hexdigit()))
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
    #[allow(dead_code)]
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

    fn get_simple_pname_version_strings(self: &Self, pname: &str) -> Option<Vec<String>> {
        self.get_pname_versions(&pname).map(|vs| {
            let mut strs = vs
                .into_iter()
                .filter_map(|v| v.text.split_once('-').map(|(v, _)| String::from(v)))
                .collect::<Vec<_>>();
            strs.sort();
            strs.dedup();
            strs
        })
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

    fn get_simple_changes(
        &self,
        pnames: impl IntoIterator<Item = impl AsRef<str>>,
    ) -> Vec<VersionChange> {
        pnames
            .into_iter()
            .filter_map(|pname| {
                let pname = pname.as_ref();
                let old_versions = self.left.get_simple_pname_version_strings(&pname);
                let new_versions = self.right.get_simple_pname_version_strings(&pname);

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

#[derive(Serialize, Debug, PartialEq, Eq)]
struct AggregatedDiffResult {
    version_changes: Vec<AggregatedVersionChange>,
    added_packages: Vec<AggregatedVersionChange>,
    removed_packages: Vec<AggregatedVersionChange>,
    reboot_packages: Vec<AggregatedVersionChange>,
}

impl AggregatedDiffResult {
    fn from_diffs(diffs: impl IntoIterator<Item = (String, DiffResult)>) -> Self {
        let mut version_changes_by_pname: HashMap<String, AggregatedVersionChange> = HashMap::new();
        let mut added_packages_by_pname: HashMap<String, AggregatedVersionChange> = HashMap::new();
        let mut removed_packages_by_pname: HashMap<String, AggregatedVersionChange> =
            HashMap::new();
        let mut reboot_packages_by_pname: HashMap<String, AggregatedVersionChange> = HashMap::new();

        for (hostname, result) in diffs {
            Self::aggregate_host_changes(
                &mut version_changes_by_pname,
                &hostname,
                result.version_changes,
            );
            Self::aggregate_host_changes(
                &mut added_packages_by_pname,
                &hostname,
                result.added_packages,
            );
            Self::aggregate_host_changes(
                &mut removed_packages_by_pname,
                &hostname,
                result.removed_packages,
            );
            Self::aggregate_host_changes(
                &mut reboot_packages_by_pname,
                &hostname,
                result.reboot_packages,
            );
        }

        Self {
            version_changes: Self::get_sorted_aggregated_changes(version_changes_by_pname),
            added_packages: Self::get_sorted_aggregated_changes(added_packages_by_pname),
            removed_packages: Self::get_sorted_aggregated_changes(removed_packages_by_pname),
            reboot_packages: Self::get_sorted_aggregated_changes(reboot_packages_by_pname),
        }
    }

    fn aggregate_host_changes(
        changes_by_pname: &mut HashMap<String, AggregatedVersionChange>,
        hostname: &str,
        changes: Vec<VersionChange>,
    ) {
        let nixos_system_pname = format!("nixos-system-{hostname}");
        for vc in changes {
            let pname = if vc.pname == nixos_system_pname {
                String::from("nixos-system")
            } else {
                vc.pname
            };

            changes_by_pname
                .entry(pname)
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
}

#[derive(Serialize, Debug, PartialEq, Eq)]
struct AggregatedVersionChange {
    pname: String,
    hosts: Vec<PerHostVersionChange>,
}

#[derive(Serialize, Debug, PartialEq, Eq)]
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

    Ok(AggregatedDiffResult::from_diffs(loaded_results))
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
    let reboot_packages = closure_pair.get_simple_changes(["linux", "systemd"]);

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
        assert_eq!(
            Package::from_store_path(Path::new(
                "/nix/store/058p7bsn5lj71qzmw5knmw7ff0ql2ly5-helix-tree-sitter-amber-c6df3ec2ec243ed76550c525e7ac3d9a10c6c814"
            )),
            Some(Package {
                pname: String::from("helix-tree-sitter-amber"),
                version: Version::new("c6df3ec2ec243ed76550c525e7ac3d9a10c6c814"),
                store_path: PathBuf::from(
                    "/nix/store/058p7bsn5lj71qzmw5knmw7ff0ql2ly5-helix-tree-sitter-amber-c6df3ec2ec243ed76550c525e7ac3d9a10c6c814"
                )
            })
        );
        assert_eq!(
            Package::from_store_path(Path::new(
                "/nix/store/058p7bsn5lj71qzmw5knmw7ff0ql2ly5-foobar-abcdef"
            )),
            Some(Package {
                pname: String::from("foobar-abcdef"),
                version: Version::new(""),
                store_path: PathBuf::from(
                    "/nix/store/058p7bsn5lj71qzmw5knmw7ff0ql2ly5-foobar-abcdef"
                )
            })
        );
    }

    #[test]
    fn package_set_from_store_paths() -> Result<()> {
        use std::path::PathBuf;

        let paths: Vec<PathBuf> = [
            "/nix/store/0a79i6pyq37lychr3gigfz81rc9vcx5k-attr-2.5.2-man",
            "/nix/store/0dnf7dm4lj3vn3y5bf0ayzkd1nh9wpvd-drkonqi-6.2.90",
            "/nix/store/0gd6844hyw16f3y5lmq1jxpx97gs5gci-util-linux-2.39.4-man",
            "/nix/store/0i443ipqsm3bdm8a93a8q1a9zg85fi3f-dbus-1.14.10-man",
            "/nix/store/0llmawy8y19db713vg8q89zjp6askr26-pipewire-1.2.3-doc",
            "/nix/store/0n2hzviid7chmcvii5swqivz385h9gfz-kio-6.7.0",
            "/nix/store/0qhkv2iqmd04s2xjiqalp4xbxv2ij0js-kwallet-pam-6.1.90",
            "/nix/store/0vlsqfyqd7brjqxb5ghawldr076zlqka-qqc2-desktop-style-6.6.0",
        ]
        .into_iter()
        .map(PathBuf::from)
        .collect();

        let set = PackageSet::from_store_paths(paths)?;

        let mut sorted_pnames = set.all_pnames();
        sorted_pnames.sort();

        assert_eq!(
            sorted_pnames,
            vec![
                "attr",
                "dbus",
                "drkonqi",
                "kio",
                "kwallet-pam",
                "pipewire",
                "qqc2-desktop-style",
                "util-linux",
            ]
        );

        assert_eq!(
            set.get_pname_versions("kio"),
            Some(vec![Version::new("6.7.0")])
        );
        assert_eq!(
            set.get_pname_version_strings("kio"),
            Some(vec![String::from("6.7.0")])
        );

        assert_eq!(set.get_pname_versions("plasma-workspace"), None);
        assert_eq!(set.get_pname_version_strings("plasma-workspace"), None);

        Ok(())
    }

    #[test]
    fn package_set_pair() -> Result<()> {
        use std::path::PathBuf;

        let left_paths: Vec<PathBuf> = [
            "/nix/store/0a79i6pyq37lychr3gigfz81rc9vcx5k-attr-2.5.2-man",
            "/nix/store/0dnf7dm4lj3vn3y5bf0ayzkd1nh9wpvd-drkonqi-6.2.90",
            "/nix/store/0gd6844hyw16f3y5lmq1jxpx97gs5gci-util-linux-2.39.4-man",
            "/nix/store/0i443ipqsm3bdm8a93a8q1a9zg85fi3f-dbus-1.14.10-man",
            "/nix/store/0llmawy8y19db713vg8q89zjp6askr26-pipewire-1.2.3-doc",
            "/nix/store/0n2hzviid7chmcvii5swqivz385h9gfz-kio-6.7.0",
            "/nix/store/0qhkv2iqmd04s2xjiqalp4xbxv2ij0js-kwallet-pam-6.1.90",
            "/nix/store/0vlsqfyqd7brjqxb5ghawldr076zlqka-qqc2-desktop-style-6.6.0",
        ]
        .into_iter()
        .map(PathBuf::from)
        .collect();

        let right_paths: Vec<PathBuf> = [
            "/nix/store/02mf752h7f5fn7989awzca4ygy94k7w7-xz-5.6.2-bin",
            "/nix/store/03clq1961wa5g4dfdlr1qbwyi7p2rw99-ffmpegthumbs-24.08.1",
            "/nix/store/0a79i6pyq37lychr3gigfz81rc9vcx5k-attr-2.5.2-man",
            "/nix/store/0dnf7dm4lj3vn3y5bf0ayzkd1nh9wpvd-drkonqi-6.1.90",
            "/nix/store/0gd6844hyw16f3y5lmq1jxpx97gs5gci-util-linux-2.39.4-man",
            "/nix/store/0i443ipqsm3bdm8a93a8q1a9zg85fi3f-dbus-1.14.10-man",
            "/nix/store/0llmawy8y19db713vg8q89zjp6askr26-pipewire-1.2.3-doc",
            "/nix/store/0n2hzviid7chmcvii5swqivz385h9gfz-kio-6.6.0",
        ]
        .into_iter()
        .map(PathBuf::from)
        .collect();

        let left = PackageSet::from_store_paths(left_paths)?;
        let right = PackageSet::from_store_paths(right_paths)?;

        let pair = PackageSetPair::new(&left, &right);

        assert_eq!(
            pair.get_version_changes(),
            vec![
                VersionChange {
                    pname: String::from("drkonqi"),
                    old_versions: Some(vec![String::from("6.2.90")]),
                    new_versions: Some(vec![String::from("6.1.90")]),
                },
                VersionChange {
                    pname: String::from("kio"),
                    old_versions: Some(vec![String::from("6.7.0")]),
                    new_versions: Some(vec![String::from("6.6.0")])
                }
            ]
        );

        assert_eq!(
            pair.get_added_packages(),
            vec![
                VersionChange {
                    pname: String::from("ffmpegthumbs"),
                    old_versions: None,
                    new_versions: Some(vec![String::from("24.08.1")])
                },
                VersionChange {
                    pname: String::from("xz"),
                    old_versions: None,
                    new_versions: Some(vec![String::from("5.6.2-bin")])
                }
            ]
        );

        assert_eq!(
            pair.get_removed_packages(),
            vec![
                VersionChange {
                    pname: String::from("kwallet-pam"),
                    old_versions: Some(vec![String::from("6.1.90")]),
                    new_versions: None
                },
                VersionChange {
                    pname: String::from("qqc2-desktop-style"),
                    old_versions: Some(vec![String::from("6.6.0")]),
                    new_versions: None
                }
            ]
        );

        assert_eq!(
            pair.get_changes(["drkonqi", "util-linux"]),
            vec![VersionChange {
                pname: String::from("drkonqi"),
                old_versions: Some(vec![String::from("6.2.90")]),
                new_versions: Some(vec![String::from("6.1.90")]),
            },]
        );

        Ok(())
    }

    #[test]
    fn aggregate_diffs_empty() {
        let result = DiffResult {
            left: String::new(),
            right: String::new(),
            version_changes: Vec::new(),
            added_packages: Vec::new(),
            removed_packages: Vec::new(),
            reboot_packages: Vec::new(),
        };

        let diffs = vec![
            (String::from("bulbasaur"), result.clone()),
            (String::from("charmander"), result.clone()),
            (String::from("squirtle"), result.clone()),
        ];

        let agg = AggregatedDiffResult::from_diffs(diffs);
        assert_eq!(
            agg,
            AggregatedDiffResult {
                version_changes: Vec::new(),
                added_packages: Vec::new(),
                removed_packages: Vec::new(),
                reboot_packages: Vec::new(),
            }
        );
    }

    #[test]
    fn aggregate_diffs() {
        let bulbasaur = DiffResult {
            left: String::new(),
            right: String::new(),
            version_changes: vec![
                VersionChange {
                    pname: String::from("firefox"),
                    old_versions: Some(vec![String::from("130.0")]),
                    new_versions: Some(vec![String::from("130.0.1")]),
                },
                VersionChange {
                    pname: String::from("jujutsu"),
                    old_versions: Some(vec![String::from("0.21.0")]),
                    new_versions: Some(vec![String::from("0.22.0")]),
                },
                VersionChange {
                    pname: String::from("nixos-system-bulbasaur"),
                    old_versions: Some(vec![String::from("25.05beta745246.11c8e6aebf3a")]),
                    new_versions: Some(vec![String::from("25.05beta745391.975ac0ab33ee")]),
                },
            ],
            added_packages: vec![VersionChange {
                pname: String::from("signal-desktop"),
                old_versions: None,
                new_versions: Some(vec![String::from("7.25.0")]),
            }],
            removed_packages: vec![VersionChange {
                pname: String::from("discord"),
                old_versions: Some(vec![String::from("0.0.67")]),
                new_versions: None,
            }],
            reboot_packages: vec![],
        };
        let charmander = DiffResult {
            left: String::new(),
            right: String::new(),
            version_changes: vec![
                VersionChange {
                    pname: String::from("jujutsu"),
                    old_versions: Some(vec![String::from("0.21.0")]),
                    new_versions: Some(vec![String::from("0.22.0")]),
                },
                VersionChange {
                    pname: String::from("nixos-system-charmander"),
                    old_versions: Some(vec![String::from("25.05beta745246.11c8e6aebf3a")]),
                    new_versions: Some(vec![String::from("25.05beta745391.975ac0ab33ee")]),
                },
            ],
            added_packages: vec![
                VersionChange {
                    pname: String::from("element-desktop"),
                    old_versions: None,
                    new_versions: Some(vec![String::from("1.11.77")]),
                },
                VersionChange {
                    pname: String::from("signal-desktop"),
                    old_versions: None,
                    new_versions: Some(vec![String::from("7.25.0")]),
                },
            ],
            removed_packages: vec![VersionChange {
                pname: String::from("emacs-pgtk"),
                old_versions: Some(vec![String::from("29.4")]),
                new_versions: None,
            }],
            reboot_packages: vec![VersionChange {
                pname: String::from("linux"),
                old_versions: Some(vec![String::from("6.6.52"), String::from("6.6.52-modules")]),
                new_versions: Some(vec![String::from("6.6.53"), String::from("6.6.53-modules")]),
            }],
        };
        let squirtle = DiffResult {
            left: String::new(),
            right: String::new(),
            version_changes: vec![
                VersionChange {
                    pname: String::from("firefox"),
                    old_versions: Some(vec![String::from("128.0")]),
                    new_versions: Some(vec![String::from("130.0.1")]),
                },
                VersionChange {
                    pname: String::from("nixos-system-squirtle"),
                    old_versions: Some(vec![String::from("25.05beta745246.11c8e6aebf3a")]),
                    new_versions: Some(vec![String::from("25.05beta745391.975ac0ab33ee")]),
                },
            ],
            added_packages: vec![VersionChange {
                pname: String::from("element-desktop"),
                old_versions: None,
                new_versions: Some(vec![String::from("1.11.77")]),
            }],
            removed_packages: vec![
                VersionChange {
                    pname: String::from("discord"),
                    old_versions: Some(vec![String::from("0.0.67")]),
                    new_versions: None,
                },
                VersionChange {
                    pname: String::from("emacs-pgtk"),
                    old_versions: Some(vec![String::from("29.4")]),
                    new_versions: None,
                },
            ],
            reboot_packages: vec![
                VersionChange {
                    pname: String::from("linux"),
                    old_versions: Some(vec![String::from("6.11"), String::from("6.11-modules")]),
                    new_versions: Some(vec![
                        String::from("6.11.1"),
                        String::from("6.11.1-modules"),
                    ]),
                },
                VersionChange {
                    pname: String::from("systemd"),
                    old_versions: Some(vec![String::from("254.2")]),
                    new_versions: Some(vec![String::from("256.0")]),
                },
            ],
        };

        let diffs = vec![
            (String::from("bulbasaur"), bulbasaur),
            (String::from("charmander"), charmander),
            (String::from("squirtle"), squirtle),
        ];

        let agg = AggregatedDiffResult::from_diffs(diffs);
        assert_eq!(
            agg,
            AggregatedDiffResult {
                version_changes: vec![
                    AggregatedVersionChange {
                        pname: String::from("firefox"),
                        hosts: vec![
                            PerHostVersionChange {
                                hostname: String::from("bulbasaur"),
                                old_versions: Some(vec![String::from("130.0")]),
                                new_versions: Some(vec![String::from("130.0.1")]),
                            },
                            PerHostVersionChange {
                                hostname: String::from("squirtle"),
                                old_versions: Some(vec![String::from("128.0")]),
                                new_versions: Some(vec![String::from("130.0.1")]),
                            }
                        ]
                    },
                    AggregatedVersionChange {
                        pname: String::from("jujutsu"),
                        hosts: vec![
                            PerHostVersionChange {
                                hostname: String::from("bulbasaur"),
                                old_versions: Some(vec![String::from("0.21.0")]),
                                new_versions: Some(vec![String::from("0.22.0")]),
                            },
                            PerHostVersionChange {
                                hostname: String::from("charmander"),
                                old_versions: Some(vec![String::from("0.21.0")]),
                                new_versions: Some(vec![String::from("0.22.0")]),
                            }
                        ]
                    },
                    AggregatedVersionChange {
                        pname: String::from("nixos-system"),
                        hosts: vec![
                            PerHostVersionChange {
                                hostname: String::from("bulbasaur"),
                                old_versions: Some(vec![String::from(
                                    "25.05beta745246.11c8e6aebf3a"
                                )]),
                                new_versions: Some(vec![String::from(
                                    "25.05beta745391.975ac0ab33ee"
                                )]),
                            },
                            PerHostVersionChange {
                                hostname: String::from("charmander"),
                                old_versions: Some(vec![String::from(
                                    "25.05beta745246.11c8e6aebf3a"
                                )]),
                                new_versions: Some(vec![String::from(
                                    "25.05beta745391.975ac0ab33ee"
                                )]),
                            },
                            PerHostVersionChange {
                                hostname: String::from("squirtle"),
                                old_versions: Some(vec![String::from(
                                    "25.05beta745246.11c8e6aebf3a"
                                )]),
                                new_versions: Some(vec![String::from(
                                    "25.05beta745391.975ac0ab33ee"
                                )]),
                            }
                        ]
                    }
                ],
                added_packages: vec![
                    AggregatedVersionChange {
                        pname: String::from("element-desktop"),
                        hosts: vec![
                            PerHostVersionChange {
                                hostname: String::from("charmander"),
                                old_versions: None,
                                new_versions: Some(vec![String::from("1.11.77")]),
                            },
                            PerHostVersionChange {
                                hostname: String::from("squirtle"),
                                old_versions: None,
                                new_versions: Some(vec![String::from("1.11.77")]),
                            }
                        ]
                    },
                    AggregatedVersionChange {
                        pname: String::from("signal-desktop"),
                        hosts: vec![
                            PerHostVersionChange {
                                hostname: String::from("bulbasaur"),
                                old_versions: None,
                                new_versions: Some(vec![String::from("7.25.0")]),
                            },
                            PerHostVersionChange {
                                hostname: String::from("charmander"),
                                old_versions: None,
                                new_versions: Some(vec![String::from("7.25.0")]),
                            }
                        ]
                    }
                ],
                removed_packages: vec![
                    AggregatedVersionChange {
                        pname: String::from("discord"),
                        hosts: vec![
                            PerHostVersionChange {
                                hostname: String::from("bulbasaur"),
                                old_versions: Some(vec![String::from("0.0.67")]),
                                new_versions: None
                            },
                            PerHostVersionChange {
                                hostname: String::from("squirtle"),
                                old_versions: Some(vec![String::from("0.0.67")]),
                                new_versions: None
                            }
                        ]
                    },
                    AggregatedVersionChange {
                        pname: String::from("emacs-pgtk"),
                        hosts: vec![
                            PerHostVersionChange {
                                hostname: String::from("charmander"),
                                old_versions: Some(vec![String::from("29.4")]),
                                new_versions: None
                            },
                            PerHostVersionChange {
                                hostname: String::from("squirtle"),
                                old_versions: Some(vec![String::from("29.4")]),
                                new_versions: None
                            }
                        ]
                    }
                ],
                reboot_packages: vec![
                    AggregatedVersionChange {
                        pname: String::from("linux"),
                        hosts: vec![
                            PerHostVersionChange {
                                hostname: String::from("charmander"),
                                old_versions: Some(vec![
                                    String::from("6.6.52"),
                                    String::from("6.6.52-modules")
                                ]),
                                new_versions: Some(vec![
                                    String::from("6.6.53"),
                                    String::from("6.6.53-modules")
                                ]),
                            },
                            PerHostVersionChange {
                                hostname: String::from("squirtle"),
                                old_versions: Some(vec![
                                    String::from("6.11"),
                                    String::from("6.11-modules")
                                ]),
                                new_versions: Some(vec![
                                    String::from("6.11.1"),
                                    String::from("6.11.1-modules")
                                ]),
                            }
                        ]
                    },
                    AggregatedVersionChange {
                        pname: String::from("systemd"),
                        hosts: vec![PerHostVersionChange {
                            hostname: String::from("squirtle"),
                            old_versions: Some(vec![String::from("254.2")]),
                            new_versions: Some(vec![String::from("256.0")]),
                        },]
                    }
                ],
            }
        );
    }
}
