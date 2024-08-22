# Update Homebrew

We are maintaining a homebrew tap for each release.

Now we have a new CLI, we want to publish it's availability for homebrew users.

- Clone the homebrew repo
- Run the `./add-version.sh --version xx.xx.xx` script. `xx.xx.xx` is the new version we just released.
- Check that there is a new formula present
- Check that the 'latest' formula has been updated to the new version.
- Check that the examples in the `README.md` changed.
- Deliver that change to the code stream.

