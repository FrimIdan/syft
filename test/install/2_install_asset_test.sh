. test_harness.sh

INSTALL_ARCHIVE_POSITIVE_CASES=0

# helper for asserting install_asset positive cases
test_helper_positive_install_asset() {
  os="$1"
  arch="$2"
  format="$3"

  # for troubleshooting
  # log_set_priority 10

  name=${PROJECT_NAME}
  binary=$(get_binary_name "${os}" "${arch}" "${PROJECT_NAME}")
  github_download=$(snapshot_download_url)
  version=$(snapshot_version)

  download_dir=$(mktemp -d)
  install_dir=$(mktemp -d)

  download_and_install_asset "${github_download}" "${download_dir}" "${install_dir}" "${name}" "${os}" "${arch}" "${version}" "${format}" "${binary}"

  expected_path="${install_dir}/${binary}"
  assertFileExists "${expected_path}" "install_asset os=${os} arch=${arch} format=${format}"

  build_dir_name="${name}"
  if [ "$os" == "darwin" ]; then
    # TODO: when we simplify the goreleaser build steps, this exception would not longer be expected
    build_dir_name="${name}-macos"
  fi

  assertFilesEqual \
    "$(snapshot_dir)/${build_dir_name}_${os}_${arch}/${binary}" \
    "${expected_path}" \
    "unable to verify installation of os=${os} arch=${arch} format=${format}"

 ((INSTALL_ARCHIVE_POSITIVE_CASES++))

  rm -rf -- "$download_dir"
  rm -rf -- "$install_dir"
}


test_install_asset_exercised_all_archive_assets() {
  expected=$(snapshot_assets_archive_count)

  assertEquals "${expected}" "${INSTALL_ARCHIVE_POSITIVE_CASES}" "did not download all possible archive assets (missing an os/arch/format variant?)"
}


worker_pid=$(setup_snapshot_server)
trap 'teardown_snapshot_server ${worker_pid}' EXIT

# exercise all possible archive assets (not rpm/deb/dmg)
run_test_case test_helper_positive_install_asset "linux" "amd64" "tar.gz"
run_test_case test_helper_positive_install_asset "linux" "arm64" "tar.gz"
run_test_case test_helper_positive_install_asset "darwin" "amd64" "tar.gz"
run_test_case test_helper_positive_install_asset "darwin" "amd64" "zip"
run_test_case test_helper_positive_install_asset "darwin" "arm64" "tar.gz"
run_test_case test_helper_positive_install_asset "darwin" "arm64" "zip"
run_test_case test_helper_positive_install_asset "windows" "amd64" "zip"

# let's make certain we covered all assets that were expected
run_test_case test_install_asset_exercised_all_archive_assets

trap - EXIT
teardown_snapshot_server "${worker_pid}"
