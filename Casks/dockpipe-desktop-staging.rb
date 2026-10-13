# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.14-staging.38463452087.1.07771827fd20"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.14-staging.38463452087.1.07771827fd20/dockpipe-desktop_0.6.14_darwin_arm64.zip"
    sha256 "110ec2f0b9e79f39673d8d25d88312ed0704a322d499c7299d3df7221d47c23f"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.14-staging.38463452087.1.07771827fd20/dockpipe-desktop_0.6.14_darwin_amd64.zip"
    sha256 "2542f84788388fd13ba276eb4a7ca85cc2fc293057661209d95d25eeaf2a91fc"
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
