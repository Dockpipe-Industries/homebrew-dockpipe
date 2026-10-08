# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.0-staging.37798113751.1.ec6228b5b663"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37798113751.1.ec6228b5b663/dockpipe-desktop_0.6.0_darwin_arm64.zip"
    sha256 "099f5b375101e4baf7620120c53ec656d0f5ae09fa9db41702fb9c998d9c3c51"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37798113751.1.ec6228b5b663/dockpipe-desktop_0.6.0_darwin_amd64.zip"
    sha256 "8a328f2b90cbb060c2645dc384e051349700a45a2e51cc41332f459970771d74"
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
