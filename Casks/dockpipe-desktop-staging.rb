# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.21-staging.39360489892.1.2bd646e637d6"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.21-staging.39360489892.1.2bd646e637d6/dockpipe-desktop_0.6.21_darwin_arm64.zip"
    sha256 "fff36ef2d465f882165194fdf0a5591bc7170a1358fb1c22272e36cb25048c07"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.21-staging.39360489892.1.2bd646e637d6/dockpipe-desktop_0.6.21_darwin_amd64.zip"
    sha256 "77f010d8ff6e0da6f64c23ffa01159b558703214a1e2d2a3ca325c6bf761f5d7"
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
