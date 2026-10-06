# Generated from a completed staging release; update through the sync workflow.
class DockpipeStaging < Formula
  desc "Run commands, packages, and workflows in isolated environments (staging)"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"
  version "0.6.0-staging.37389279395.1.9725dee90d4d"
  license "Apache-2.0"

  depends_on :macos
  conflicts_with "dockpipe", because: "both install the dockpipe command"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37389279395.1.9725dee90d4d/dockpipe_0.6.0_darwin_arm64.tar.gz"
    sha256 "71323908852ed8e362ee8bd7fc55f67a98e56e21374371a9402b78996f054a32"

    resource "packages" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37389279395.1.9725dee90d4d/dockpipe-packages_0.6.0_darwin-arm64.tar.gz"
      sha256 "dee8ad5590fb8c9728616ece4d676a577d110c0bd20469910638b17397508990"
    end
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37389279395.1.9725dee90d4d/dockpipe_0.6.0_darwin_amd64.tar.gz"
    sha256 "3eb9f71eb7a34b5a9f13368153ae183d3e57a17c7d1a5432c3b72284e0b78c87"

    resource "packages" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37389279395.1.9725dee90d4d/dockpipe-packages_0.6.0_darwin-amd64.tar.gz"
      sha256 "6bf8334e112c76b499ab67217cbd40d7af35a11bd5f0db8b275e8d82506daed1"
    end
  end

  def install
    (libexec/"bin").install "dockpipe"
    resource("packages").stage do
      store = libexec/"share/dockpipe"
      store.install "packages-store-manifest.json"
      (store/"packages/core").install Dir["dockpipe-core-*.tar.gz"]
      (store/"packages/workflows").install Dir["dockpipe-workflow-*.tar.gz"]
      (store/"packages/resolvers").install Dir["dockpipe-resolver-*.tar.gz"]
    end

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
    require "digest"
    store = libexec/"share/dockpipe"
    packages = JSON.parse((store/"packages-store-manifest.json").read).fetch("packages")
    { "core" => [packages.fetch("core")],
      "workflows" => packages.fetch("workflows"),
      "resolvers" => packages.fetch("resolvers") }.each do |kind, entries|
      refute_empty entries
      entries.each do |entry|
        archive = store/"packages"/kind/entry.fetch("tarball")
        assert_equal entry.fetch("sha256"), Digest::SHA256.file(archive).hexdigest
      end
    end
  end
end
