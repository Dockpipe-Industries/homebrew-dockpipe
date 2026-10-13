# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.10-staging.38324529693.1.b0c88abc124f"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.10-staging.38324529693.1.b0c88abc124f/dockpipe-desktop_0.6.10_darwin_arm64.zip"
    sha256 "ad24e1086f30850a3e3dc1297c5e263c95761afac0fb930737e79945f21eb30f"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.10-staging.38324529693.1.b0c88abc124f/dockpipe-desktop_0.6.10_darwin_amd64.zip"
    sha256 "0ab563f0ad4795f628485666637fb510a9524e9284023844cc2d40751757d145"
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
