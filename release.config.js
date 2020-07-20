module.exports = {
  extends: ['semantic-release-commit-filter'],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    '@semantic-release/changelog',
    [
      'semantic-release-rubygem',
      {
        updateGemfileLock: true,
      }
    ],
    [
      '@semantic-release/git',
      {
        // eslint-disable-next-line no-template-curly-in-string
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
        assets: ['CHANGELOG.md', '*.lock', 'lib/**/version.rb'],
      },
    ],
    '@semantic-release/github',
  ],
};
