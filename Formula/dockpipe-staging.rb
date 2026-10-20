# Generated from a completed staging release; update through the sync workflow.
class DockpipeStaging < Formula
  desc "Run commands, packages, and workflows in isolated environments (staging)"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"
  version "0.6.21-staging.39360489892.1.2bd646e637d6"
  license "Apache-2.0"

  depends_on :macos

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.21-staging.39360489892.1.2bd646e637d6/dockpipe_0.6.21_darwin_arm64.tar.gz"
    sha256 "c0b3a4edbf5de5d88667af35efc4b2a16c8e7fb62104049d3f62b85ad78ab75f"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.21-staging.39360489892.1.2bd646e637d6/dockpipe-core-0.6.21.tar.gz"
      sha256 "be2222b99662d1fe107c414e76469d2c32c23fb9031b9eeea1935576b9f3d5cf"
    end
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.21-staging.39360489892.1.2bd646e637d6/dockpipe_0.6.21_darwin_amd64.tar.gz"
    sha256 "6bcb7698da93fea3d8a9768c96412299316c8b0aac7f74bcd4a924137e79fc5a"

    resource "core" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.21-staging.39360489892.1.2bd646e637d6/dockpipe-core-0.6.21.tar.gz"
      sha256 "be2222b99662d1fe107c414e76469d2c32c23fb9031b9eeea1935576b9f3d5cf"
    end
  end

  def install
    (libexec/"bin").install "dockpipe"
    # Homebrew already fetched and verified this resource before entering the
    # install sandbox. Fetching again tries to acquire a download-cache lock.
    # Keep the verified archive intact; optional packages are installed on demand.
    core = resource("core").cached_download
    (libexec/"share/dockpipe/packages/core").install core => "dockpipe-core-0.6.21.tar.gz"

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
    assert_equal ["packages/core/dockpipe-core-0.6.21.tar.gz"], installed_files
    inventory = JSON.parse(shell_output("#{bin}/dockpipe package list --format json --workdir #{testpath}"))
    assert_empty inventory.fetch("warnings")
    refute_empty inventory.fetch("packages")
    assert_equal ["core"], inventory.fetch("packages").map { |package| package.fetch("kind") }.uniq
  end
end
