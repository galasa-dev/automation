# Update Homebrew

We are maintaining a homebrew tap for each release.

Now we have a new CLI, we want to publish it's availability for homebrew users.

- Clone the homebrew-tap repo
- Run the `./add-version.sh --version xx.xx.xx` script. `xx.xx.xx` is the new version we just released.
- Check that there is a new formula present
- Check that the 'latest' formula has been updated to the new version.
- Check that the examples in the `README.md` changed.
- Deliver that change to the code stream.

# Update Scoop

We are also maintaining a scoop bucket for each release.

- Clone the scoop-bucket repo
- Run the `./add-version.sh --version xx.xx.xx` script. `xx.xx.xx` is the new version we just released.
- Check that there is a new json manifest in the `/bucket` directory for the new version.
- Check that `bucket/galasactl.json` has been updated to the new version.
- Deliver that change to the code stream.
