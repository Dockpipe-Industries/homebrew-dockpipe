# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.41-staging.45546622637.1.eef1e3f58bb1"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.41-staging.45546622637.1.eef1e3f58bb1/dockpipe-desktop_0.6.41_darwin_arm64.zip"
    sha256 "07e8dc4b55f353838adf4c5fc54bb617893e1ac85e6dab4dc3c990987daee1a8"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.41-staging.45546622637.1.eef1e3f58bb1/dockpipe-desktop_0.6.41_darwin_amd64.zip"
    sha256 "83877b346454abc50ef6b1b9d2bdba8a796673de4839afeb96b8295ef263bc3e"
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
