# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.8-staging.38309329321.1.9ff64e91c254"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.8-staging.38309329321.1.9ff64e91c254/dockpipe-desktop_0.6.8_darwin_arm64.zip"
    sha256 "77c737c801eaa2028bb25b564a38624c595c92129ce59293fed87e52b4643c03"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.8-staging.38309329321.1.9ff64e91c254/dockpipe-desktop_0.6.8_darwin_amd64.zip"
    sha256 "f2df1bf0bdb352298c06bb9e82141549c4e0e0bd5bb9953a39d075755ac1ff81"
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
