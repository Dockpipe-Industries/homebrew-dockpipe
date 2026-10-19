# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.20-staging.39285769512.1.0399bb37bb7d"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.20-staging.39285769512.1.0399bb37bb7d/dockpipe-desktop_0.6.20_darwin_arm64.zip"
    sha256 "5835b4c6e283db2227a58d380dea9918331a591506c722c5623b56eb2e9ccf78"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.20-staging.39285769512.1.0399bb37bb7d/dockpipe-desktop_0.6.20_darwin_amd64.zip"
    sha256 "151ff28afbff2e505df94ee527d33b64b8060ef3ab75a351a46dd02c3d6553dc"
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
