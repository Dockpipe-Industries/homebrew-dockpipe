# Generated from a completed staging release; update through the sync workflow.
class DockpipeStaging < Formula
  desc "Run commands, packages, and workflows in isolated environments (staging)"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"
  version "0.6.3-staging.37959504785.1.4da6948415b9"
  license "Apache-2.0"

  depends_on :macos

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.3-staging.37959504785.1.4da6948415b9/dockpipe_0.6.3_darwin_arm64.tar.gz"
    sha256 "09b242a9d518f324fa3881cea94376c5f0752dc2934ebac5abbe3fbebe8f8bee"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.3-staging.37959504785.1.4da6948415b9/dockpipe-core-0.6.3.tar.gz"
      sha256 "3b0d276774de80fbd8a4ae21519162b84fcecc007ea440eb72683c9bfb11c063"
    end
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.3-staging.37959504785.1.4da6948415b9/dockpipe_0.6.3_darwin_amd64.tar.gz"
    sha256 "4c2dd83b66f4a43d2b27259c12e2673c14701fb5f87f1b7e914eaa05cb089ec9"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.3-staging.37959504785.1.4da6948415b9/dockpipe-core-0.6.3.tar.gz"
      sha256 "3b0d276774de80fbd8a4ae21519162b84fcecc007ea440eb72683c9bfb11c063"
    end
  end

  def install
    (libexec/"bin").install "dockpipe"
    # Homebrew already fetched and verified this resource before entering the
    # install sandbox. Fetching again tries to acquire a download-cache lock.
    # Keep the verified archive intact; optional packages are installed on demand.
    core = resource("core").cached_download
    (libexec/"share/dockpipe/packages/core").install core => "dockpipe-core-0.6.3.tar.gz"

    # Use the existing package-root override so Homebrew owns the entire install.
    (bin/"dockpipe").write <<~SH
      #!/bin/sh
      export DOCKPIPE_SYSTEM_ROOT="${DOCKPIPE_SYSTEM_ROOT:-#{libexec}/share/dockpipe}"
      exec "#{libexec}/bin/dockpipe" "$@"
    SH
    chmod 0755, bin/"dockpipe"
  end

  def caveats
    <<~EOS
      This is a staging candidate. The command is dockpipe.
      It uses the normal Dockpipe user data unless DOCKPIPE_GLOBAL_ROOT is set.
      Docker is needed only for workflows that use containers.
    EOS
  end

  test do
    ENV["DOCKPIPE_GLOBAL_ROOT"] = (testpath/"global").to_s
    ENV["XDG_STATE_HOME"] = (testpath/"state").to_s
    ENV["XDG_CACHE_HOME"] = (testpath/"cache").to_s
    (testpath/"workflow.yml").write <<~YAML
      name: homebrew-smoke
      docker_preflight: false
      steps:
        - id: native
          kind: host
          cwd: repo
          run: smoke.sh
    YAML
    (testpath/"smoke.sh").write "#!/bin/bash\nprintf brew-ok > result.txt\n"
    chmod 0755, testpath/"smoke.sh"
    system bin/"dockpipe", "--workflow-file", testpath/"workflow.yml", "--workdir", testpath
    assert_equal "brew-ok", (testpath/"result.txt").read

    require "json"
    store = libexec/"share/dockpipe"
    installed_files = Dir.glob("#{store}/**/*").filter_map do |path|
      Pathname(path).relative_path_from(store).to_s if File.file?(path)
    end
    assert_equal ["packages/core/dockpipe-core-0.6.3.tar.gz"], installed_files
    inventory = JSON.parse(shell_output("#{bin}/dockpipe package list --format json --workdir #{testpath}"))
    assert_empty inventory.fetch("warnings")
    refute_empty inventory.fetch("packages")
    assert_equal ["core"], inventory.fetch("packages").map { |package| package.fetch("kind") }.uniq
  end
end
