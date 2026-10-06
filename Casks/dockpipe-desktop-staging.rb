# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.0-staging.37427226861.2.32151189bdd0"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37427226861.2.32151189bdd0/dockpipe-desktop_0.6.0_darwin_arm64.zip"
    sha256 "639175b5a3efbfd0f08fa286bcbe911fa54daa1b3bf79603a7e5dd2b8ceea5a9"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37427226861.2.32151189bdd0/dockpipe-desktop_0.6.0_darwin_amd64.zip"
    sha256 "4657e0ae6eedae28ad9e32c14f11d7e2fefd40f34db5fec906a73d27bb2172f5"
  end

  name "DockPipe Desktop (staging)"
  desc "Desktop launcher and command-line runtime for DockPipe workflows"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"

  depends_on macos: ">= :ventura"
  depends_on formula: "dockpipe-industries/dockpipe/dockpipe-staging"

  app "DockPipe.app"

  caveats <<~EOS
    This is a staging candidate. Open DockPipe from Applications.
    The dockpipe command is provided by the dockpipe-staging formula.
    Use this cask or the direct DMG installer, not both.
    Unsigned staging builds have not passed Apple's notarization checks.
  EOS
end
