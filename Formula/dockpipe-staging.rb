# Generated from a completed staging release; update through the sync workflow.
class DockpipeStaging < Formula
  desc "Run commands, packages, and workflows in isolated environments (staging)"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"
  version "0.6.1-staging.37817108070.1.cdc7ac2f9c36"
  license "Apache-2.0"

  depends_on :macos

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.1-staging.37817108070.1.cdc7ac2f9c36/dockpipe_0.6.1_darwin_arm64.tar.gz"
    sha256 "22441d77d5f649e91f7b1f8266cae6b7887848c3dd328a754ccd9c7cf4682fb5"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.1-staging.37817108070.1.cdc7ac2f9c36/dockpipe-core-0.6.1.tar.gz"
      sha256 "545c41872f0b4a1c9bfa8dfadacdfbc040ee3c09b9d213bcfd19a1bd359edebc"
    end
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.1-staging.37817108070.1.cdc7ac2f9c36/dockpipe_0.6.1_darwin_amd64.tar.gz"
    sha256 "c220d9d9261fb82e798ebcf571c9eb5f8a33e80e8e4a040d8c6ae2ef91b95410"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.1-staging.37817108070.1.cdc7ac2f9c36/dockpipe-core-0.6.1.tar.gz"
      sha256 "545c41872f0b4a1c9bfa8dfadacdfbc040ee3c09b9d213bcfd19a1bd359edebc"
    end
  end

  def install
    (libexec/"bin").install "dockpipe"
    # Keep the verified archive intact. Optional packages are installed on demand.
    core = resource("core").fetch
    (libexec/"share/dockpipe/packages/core").install core => "dockpipe-core-0.6.1.tar.gz"

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
    assert_equal ["packages/core/dockpipe-core-0.6.1.tar.gz"], installed_files
    inventory = JSON.parse(shell_output("#{bin}/dockpipe package list --format json --workdir #{testpath}"))
    assert_empty inventory.fetch("warnings")
    refute_empty inventory.fetch("packages")
    assert_equal ["core"], inventory.fetch("packages").map { |package| package.fetch("kind") }.uniq
  end
end
