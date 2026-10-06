# Generated from a completed staging release; update through the sync workflow.
class DockpipeStaging < Formula
  desc "Run commands, packages, and workflows in isolated environments (staging)"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"
  version "0.6.0-staging.37427226861.2.32151189bdd0"
  license "Apache-2.0"

  depends_on :macos

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37427226861.2.32151189bdd0/dockpipe_0.6.0_darwin_arm64.tar.gz"
    sha256 "34fc2957037eeecb1f579ec8380003543d38ca61aa3c8856db512333e02eae79"

    resource "packages" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37427226861.2.32151189bdd0/dockpipe-packages_0.6.0_darwin-arm64.tar.gz"
      sha256 "abf7684854f08bdfb529d0ec9b83b5f094b6d1e5440d547a4ecf64821c34e314"
    end
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37427226861.2.32151189bdd0/dockpipe_0.6.0_darwin_amd64.tar.gz"
    sha256 "56861534dc37480027ebc99d6cbde57e3ce4155b4aecaa5d94d7f52fe1161ebe"

    resource "packages" do
      url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37427226861.2.32151189bdd0/dockpipe-packages_0.6.0_darwin-amd64.tar.gz"
      sha256 "f095bfba2f420d4632ecec4d257a80bc56cb0e6bf2847a07dc30f7619e3336ab"
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
