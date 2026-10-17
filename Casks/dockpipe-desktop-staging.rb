# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.18-staging.39067200643.1.a48458c522c9"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.18-staging.39067200643.1.a48458c522c9/dockpipe-desktop_0.6.18_darwin_arm64.zip"
    sha256 "8b2e8815bf338ea4acf880c4604075cad3a1636d4eec0077eaf96871bbc5b0cc"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.18-staging.39067200643.1.a48458c522c9/dockpipe-desktop_0.6.18_darwin_amd64.zip"
    sha256 "838949421ae6f61828938dbab7f066d64df9fd6dcae20e2507963adc3888d8bb"
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
