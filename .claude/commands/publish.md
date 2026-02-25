# Publish Ruby Gem

Publish a new version of this Ruby gem. Follow these steps exactly:

## 1. Pre-flight checks
- Run `bundle exec rspec` to ensure all tests pass. Stop if any fail.
- Run `git status` to see the current state of the working tree.
- Read `lib/sage/version.rb` to determine the current version.

## 2. Bump version
- Determine the appropriate version bump (patch, minor, or major) based on the changes. Ask the user if unclear.
- Update the version in `lib/sage/version.rb`.

## 3. Commit changes
- Stage all relevant changed files (including the version bump and any uncommitted work).
- Commit with a descriptive message summarizing the changes.

## 4. Build the gem
```
gem build sage.gemspec
```
This creates a `.gem` file in the project root.

## 5. Push to RubyGems
```
gem push sage-rails-<VERSION>.gem
```
Replace `<VERSION>` with the version from step 2.

## 6. Tag, push, and create GitHub release
```
git tag v<VERSION>
git push origin main
git push origin v<VERSION>
gh release create v<VERSION> --title "v<VERSION>" --latest
```

## 7. Clean up
Remove the `.gem` file from the project root (it's in .gitignore but clean up anyway):
```
rm sage-rails-<VERSION>.gem
```

## 8. Confirm
Report the published version and RubyGems URL: `https://rubygems.org/gems/sage-rails`
