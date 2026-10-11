# Generated from a completed staging release; update through the sync workflow.
class DockpipeStaging < Formula
  desc "Run commands, packages, and workflows in isolated environments (staging)"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"
  version "0.6.5-staging.38149878120.1.95d3a9815b7f"
  license "Apache-2.0"

  depends_on :macos

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.5-staging.38149878120.1.95d3a9815b7f/dockpipe_0.6.5_darwin_arm64.tar.gz"
    sha256 "13e6c35afd6ea31cedff12387eaecb0d08280390fc90eefa9c9e13d54c16f50e"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.5-staging.38149878120.1.95d3a9815b7f/dockpipe-core-0.6.5.tar.gz"
      sha256 "34401ddebb9bb1be0313777f52b22e8e93b44662c31b83a3d4b12169a3953bac"
    end
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.5-staging.38149878120.1.95d3a9815b7f/dockpipe_0.6.5_darwin_amd64.tar.gz"
    sha256 "0aa8ad9c1f53a04e991a72addcb4daff981e4bdc545e01d50647cd19029c0a14"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.5-staging.38149878120.1.95d3a9815b7f/dockpipe-core-0.6.5.tar.gz"
      sha256 "34401ddebb9bb1be0313777f52b22e8e93b44662c31b83a3d4b12169a3953bac"
    end
  end

  def install
    (libexec/"bin").install "dockpipe"
    # Homebrew already fetched and verified this resource before entering the
    # install sandbox. Fetching again tries to acquire a download-cache lock.
    # Keep the verified archive intact; optional packages are installed on demand.
    core = resource("core").cached_download
    (libexec/"share/dockpipe/packages/core").install core => "dockpipe-core-0.6.5.tar.gz"

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
    assert_equal ["packages/core/dockpipe-core-0.6.5.tar.gz"], installed_files
    inventory = JSON.parse(shell_output("#{bin}/dockpipe package list --format json --workdir #{testpath}"))
    assert_empty inventory.fetch("warnings")
    refute_empty inventory.fetch("packages")
    assert_equal ["core"], inventory.fetch("packages").map { |package| package.fetch("kind") }.uniq
  end
end
