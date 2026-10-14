# Generated from a completed staging release; update through the sync workflow.
class DockpipeStaging < Formula
  desc "Run commands, packages, and workflows in isolated environments (staging)"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"
  version "0.6.15-staging.38500140985.1.9cfcdcbb5441"
  license "Apache-2.0"

  depends_on :macos

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.15-staging.38500140985.1.9cfcdcbb5441/dockpipe_0.6.15_darwin_arm64.tar.gz"
    sha256 "c76020893aac0e2772acf4ee3ff2bf22e6086e3db043388aa698056be5b00aac"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.15-staging.38500140985.1.9cfcdcbb5441/dockpipe-core-0.6.15.tar.gz"
      sha256 "57574ccbad71e1b74abe9583a037fc030e78f910f4d0207b90543f882943c3f9"
    end
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.15-staging.38500140985.1.9cfcdcbb5441/dockpipe_0.6.15_darwin_amd64.tar.gz"
    sha256 "6a5ce210b7023893d492d10c37a7eff914c84d9380748e6a4c485905e0cd9ac7"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.15-staging.38500140985.1.9cfcdcbb5441/dockpipe-core-0.6.15.tar.gz"
      sha256 "57574ccbad71e1b74abe9583a037fc030e78f910f4d0207b90543f882943c3f9"
    end
  end

  def install
    (libexec/"bin").install "dockpipe"
    # Homebrew already fetched and verified this resource before entering the
    # install sandbox. Fetching again tries to acquire a download-cache lock.
    # Keep the verified archive intact; optional packages are installed on demand.
    core = resource("core").cached_download
    (libexec/"share/dockpipe/packages/core").install core => "dockpipe-core-0.6.15.tar.gz"

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
    assert_equal ["packages/core/dockpipe-core-0.6.15.tar.gz"], installed_files
    inventory = JSON.parse(shell_output("#{bin}/dockpipe package list --format json --workdir #{testpath}"))
    assert_empty inventory.fetch("warnings")
    refute_empty inventory.fetch("packages")
    assert_equal ["core"], inventory.fetch("packages").map { |package| package.fetch("kind") }.uniq
  end
end
