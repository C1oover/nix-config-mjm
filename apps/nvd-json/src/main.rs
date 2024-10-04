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
    Aggregate(AggregateArgs),
}

#[derive(Args)]
struct DiffArgs {
    left: std::path::PathBuf,
    right: std::path::PathBuf,
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
        bail!("path {} does not exist", left.display())
    }

    if !right.try_exists()? {
        bail!("path {} does not exist", right.display())
    }

    let left_canonical = left.canonicalize()?;
    let right_canonical = right.canonicalize()?;
    let boot_canonical = std::path::Path::new("/run/booted-system").canonicalize()?;

    // let left_sw = left_canonical.join("sw");
    // let right_sw = right_canonical.join("sw");

    // let (left_selected, right_selected) = if left_sw.exists() && right_sw.exists() {
    //     (
    //         PackageSet::from_direct_dependencies(&left_sw.canonicalize()?)?,
    //         PackageSet::from_direct_dependencies(&right_sw.canonicalize()?)?,
    //     )
    // } else {
    //     (
    //         PackageSet::from_direct_dependencies(&left_canonical)?,
    //         PackageSet::from_direct_dependencies(&right_canonical)?,
    //     )
    // };

    let left_closure = PackageSet::from_closure(&left_canonical)?;
    let right_closure = PackageSet::from_closure(&right_canonical)?;
    let boot_closure = PackageSet::from_closure(&boot_canonical)?;

    // let left_selected_pnames = HashSet::<String>::from_iter(left_selected.all_pnames());
    // let right_selected_pnames = HashSet::<String>::from_iter(right_selected.all_pnames());

    let left_closure_pnames = HashSet::<String>::from_iter(left_closure.all_pnames());
    let right_closure_pnames = HashSet::from_iter(right_closure.all_pnames());

    // let selected_in_either = left_selected_pnames.union(&right_selected_pnames);
    let present_in_both = left_closure_pnames.intersection(&right_closure_pnames);

    let mut changed_version_pnames = Vec::new();
    for pname in present_in_both {
        if left_closure.get_pname_versions(pname) != right_closure.get_pname_versions(pname) {
            changed_version_pnames.push(pname.to_string());
        }
    }
    changed_version_pnames.sort();

    let version_changes = changed_version_pnames
        .iter()
        .map(|pname| VersionChange {
            pname: pname.clone(),
            old_versions: Some(
                left_closure
                    .get_pname_versions(&pname)
                    .unwrap()
                    .iter()
                    .map(|v| v.text.clone())
                    .collect(),
            ),
            new_versions: Some(
                right_closure
                    .get_pname_versions(&pname)
                    .unwrap()
                    .iter()
                    .map(|v| v.text.clone())
                    .collect(),
            ),
        })
        .collect();

    let mut added_package_pnames: Vec<&String> = right_closure_pnames
        .difference(&left_closure_pnames)
        .collect();
    added_package_pnames.sort();

    let added_packages = added_package_pnames
        .iter()
        .map(|pname| VersionChange {
            pname: pname.to_string(),
            old_versions: None,
            new_versions: Some(
                right_closure
                    .get_pname_versions(&pname)
                    .unwrap()
                    .iter()
                    .map(|v| v.text.clone())
                    .collect(),
            ),
        })
        .collect();

    let mut removed_package_pnames: Vec<&String> = left_closure_pnames
        .difference(&right_closure_pnames)
        .collect();
    removed_package_pnames.sort();

    let removed_packages = removed_package_pnames
        .iter()
        .map(|pname| VersionChange {
            pname: pname.to_string(),
            old_versions: Some(
                left_closure
                    .get_pname_versions(&pname)
                    .unwrap()
                    .iter()
                    .map(|v| v.text.clone())
                    .collect(),
            ),
            new_versions: None,
        })
        .collect();

    let reboot_pnames = ["linux", "systemd"];
    let reboot_packages = reboot_pnames
        .into_iter()
        .filter_map(|pname| {
            let old_versions = boot_closure.get_pname_versions(pname);
            let new_versions = right_closure.get_pname_versions(pname);

            if old_versions == new_versions {
                None
            } else {
                Some(VersionChange {
                    pname: pname.to_string(),
                    old_versions: old_versions.map(|vs| vs.into_iter().map(|v| v.text).collect()),
                    new_versions: new_versions.map(|vs| vs.into_iter().map(|v| v.text).collect()),
                })
            }
        })
        .collect();

    Ok(DiffResult {
        left: left_canonical.to_string_lossy().to_string(),
        right: right_canonical.to_string_lossy().to_string(),
        version_changes,
        added_packages,
        removed_packages,
        reboot_packages,
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

#[derive(Debug)]
struct Package {
    pname: String,
    version: Version,
    store_path: std::path::PathBuf,
}

impl Package {
    fn from_store_path(path: &std::path::Path) -> Option<Self> {
        let basename = path.file_name()?.to_str()?;

        let mut iter = basename.split('-');
        iter.next()?;

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

        let paths: Vec<std::path::PathBuf> = output_str
            .trim_end()
            .lines()
            .map(|line| line.into())
            .collect();

        let packages = paths
            .iter()
            .map(|path| -> Result<Package> {
                Ok(Package::from_store_path(path).ok_or(format_err!(
                    "could not get package info from store path {}",
                    path.display()
                ))?)
            })
            .collect::<Result<Vec<Package>>>()?;

        Ok(Self::new(packages, paths))
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
        .collect::<Result<Vec<(String, DiffResult)>>>()?;

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
