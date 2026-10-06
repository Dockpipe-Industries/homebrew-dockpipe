# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.0-staging.37414177001.1.48a5701e3652"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37414177001.1.48a5701e3652/dockpipe-desktop_0.6.0_darwin_arm64.zip"
    sha256 "16691ba1d813cdea22cf4ab241fd1cf8ae0f54888ec0e2a474be819fa9b9ce1c"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.0-staging.37414177001.1.48a5701e3652/dockpipe-desktop_0.6.0_darwin_amd64.zip"
    sha256 "dc9f445834ae0f9df1b443ea4d9fd3f41245c73dc7bac255031d720c8b61a447"
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
