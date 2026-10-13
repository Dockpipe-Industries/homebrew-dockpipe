# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.13-staging.38358889476.1.cbb7af7c6a95"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.13-staging.38358889476.1.cbb7af7c6a95/dockpipe-desktop_0.6.13_darwin_arm64.zip"
    sha256 "c2e22ae636e03fff2a3f56f63276c97df7c752aa7bc93accab06f36395474232"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.13-staging.38358889476.1.cbb7af7c6a95/dockpipe-desktop_0.6.13_darwin_amd64.zip"
    sha256 "1737c661e27b9ca26ebb8767453608c53b4145217c1ca1b5cf1b0e6179b2dd9b"
  end

  name "Dockpipe Desktop (staging)"
  desc "Desktop launcher and command-line runtime for Dockpipe workflows"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"

  depends_on macos: ">= :ventura"
  depends_on formula: "dockpipe-industries/dockpipe/dockpipe-staging"

  app "DockPipe.app"

  caveats <<~EOS
    This is a staging candidate. Open Dockpipe from Applications.
    The dockpipe command is provided by the dockpipe-staging formula.
    Use this cask or the direct DMG installer, not both.
    Unsigned staging builds have not passed Apple's notarization checks.
  EOS
end
