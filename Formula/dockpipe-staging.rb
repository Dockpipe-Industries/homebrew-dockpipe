# Generated from a completed staging release; update through the sync workflow.
class DockpipeStaging < Formula
  desc "Run commands, packages, and workflows in isolated environments (staging)"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"
  version "0.6.2-staging.37880486276.1.2073df19f667"
  license "Apache-2.0"

  depends_on :macos

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.2-staging.37880486276.1.2073df19f667/dockpipe_0.6.2_darwin_arm64.tar.gz"
    sha256 "198e0a06273a70080704d8c0e2b3b7afddd35c74a206c8c0e3c7f1f30485c8bd"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.2-staging.37880486276.1.2073df19f667/dockpipe-core-0.6.2.tar.gz"
      sha256 "bb28bffef1718a0aba16e4cf652cb15742db52155e43a43f117b80c6c8c38cdb"
    end
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.2-staging.37880486276.1.2073df19f667/dockpipe_0.6.2_darwin_amd64.tar.gz"
    sha256 "d1161c0561aeb9d1426e9d2597135999f4f5d0218e1e98210d91bda81cd20aec"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.2-staging.37880486276.1.2073df19f667/dockpipe-core-0.6.2.tar.gz"
      sha256 "bb28bffef1718a0aba16e4cf652cb15742db52155e43a43f117b80c6c8c38cdb"
    end
  end

  def install
    (libexec/"bin").install "dockpipe"
    # Keep the verified archive intact. Optional packages are installed on demand.
    core = resource("core").fetch
    (libexec/"share/dockpipe/packages/core").install core => "dockpipe-core-0.6.2.tar.gz"

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
      It uses the normal DockPipe user data unless DOCKPIPE_GLOBAL_ROOT is set.
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
    assert_equal ["packages/core/dockpipe-core-0.6.2.tar.gz"], installed_files
    inventory = JSON.parse(shell_output("#{bin}/dockpipe package list --format json --workdir #{testpath}"))
    assert_empty inventory.fetch("warnings")
    refute_empty inventory.fetch("packages")
    assert_equal ["core"], inventory.fetch("packages").map { |package| package.fetch("kind") }.uniq
  end
end
