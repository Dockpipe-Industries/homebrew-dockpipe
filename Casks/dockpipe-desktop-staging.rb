# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.2-staging.37880486276.1.2073df19f667"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.2-staging.37880486276.1.2073df19f667/dockpipe-desktop_0.6.2_darwin_arm64.zip"
    sha256 "b594416b2cfc309e44a096acec683f3672bb96ac1a30dd030c33555c9f69baad"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.2-staging.37880486276.1.2073df19f667/dockpipe-desktop_0.6.2_darwin_amd64.zip"
    sha256 "788ddedda469b9b146972f957ace2f0f8d191c782e78b7ef13d428f2629fddab"
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
