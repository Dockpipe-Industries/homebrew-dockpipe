# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.4-staging.38074870242.1.bd9ed481ef23"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.4-staging.38074870242.1.bd9ed481ef23/dockpipe-desktop_0.6.4_darwin_arm64.zip"
    sha256 "53eb241e911932b1b390f48d31473062d77964f6938dd56782429d89578bb8ef"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.4-staging.38074870242.1.bd9ed481ef23/dockpipe-desktop_0.6.4_darwin_amd64.zip"
    sha256 "459dea298627aa76403cda55474b27e74b7ff30516142fe20827f64e6e4b4a93"
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
