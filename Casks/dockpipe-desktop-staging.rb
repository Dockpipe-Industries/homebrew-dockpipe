# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.16-staging.38567355491.1.70d207f11d1f"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.16-staging.38567355491.1.70d207f11d1f/dockpipe-desktop_0.6.16_darwin_arm64.zip"
    sha256 "208bee2c5470519f9f435bdbef2f7be6c87e3e4cb4d7813310a55150c993e104"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.16-staging.38567355491.1.70d207f11d1f/dockpipe-desktop_0.6.16_darwin_amd64.zip"
    sha256 "088c2b813d68f7a6883e38fed3fa724a65ab66d50b6373e3b3c502f5285ef2ed"
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
