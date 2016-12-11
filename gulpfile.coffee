gulp = require 'gulp'
$ = do require 'gulp-load-plugins'

$.remapIstanbul = require 'remap-istanbul/lib/gulpRemapIstanbul'
$.del = require 'del'
$.merge = require 'merge2'
$.runSequence = require 'run-sequence'
  .use gulp

argv = require 'yargs'
  .argv

if argv.production
  argv.mode = 'production'
else if argv.development
  argv.mode = 'development'
else if process.env.NODE_ENV isnt undefined
  argv.mode = process.env.NODE_ENV
else
  argv.mode = 'development'

tsProject = $.typescript.createProject 'tsconfig.json',
  typescript: require 'typescript'
testTsProject = $.typescript.createProject 'tsconfig.json',
  typescript: require 'typescript'

# for mocha
require 'ts-node/register'
require 'source-map-support/register'

mochaOptions = (reporterType) ->
  reporter: process.env.MOCHA_REPORTER || reporterType
  timeout: 5000

gulp.task 'build:tsc', ->
  tsResult = gulp.src [
    'lib/**/*.ts'
    'test/**/*.ts'
  ]
    .pipe $.sourcemaps.init()
    .pipe testTsProject $.typescript.reporter.defaultReporter()

  $.merge [
    tsResult.js
    tsResult.dts
  ]
    .pipe $.sourcemaps.write()
    .pipe gulp.dest 'dist'

gulp.task 'build:dts', ->
  gulp.src [
    'lib/**/*.d.ts'
  ]
    .pipe gulp.dest 'dist/lib'

gulp.task 'build:ts', [
  'build:tsc'
  'build:dts'
]

gulp.task 'build', [
  'build:ts'
]

tslint = require 'tslint'

gulp.task 'lint:ts', ->
  gulp.src [
    'lib/**/*.ts'
    'test/**/*.ts'
  ]
    .pipe $.tslint
      tslint: tslint
    .pipe $.tslint.report()

gulp.task 'lint', (cb) ->
  $.runSequence 'lint:ts'
    , cb

gulp.task 'test:ts', ->
  gulp.src [
    'test/**/*.test.ts'
  ], { read: false }
    .pipe $.mocha mochaOptions {
      production: 'spec'
      development: 'nyan'
    }[argv.mode]

gulp.task 'test', (cb) ->
  $.runSequence 'test:ts'
    , cb

gulp.task 'coverage:ts-pre', [
  'build:ts'
], ->
  gulp.src [
    'dist/lib/**/*.js'
  ]
    .pipe $.istanbul()
    .pipe $.istanbul.hookRequire()

gulp.task 'coverage:ts-trans', [
  'coverage:ts-pre'
], ->
  gulp.src [
    'dist/test/**/*.test.js'
  ], { read: false }
    .pipe $.mocha mochaOptions {
      production: 'progress'
      development: 'nyan'
    }[argv.mode]
    .pipe $.istanbul.writeReports
      reporters: ['lcov', 'json']

gulp.task 'coverage:ts', [
  'coverage:ts-trans'
], ->
  gulp.src [
    'coverage/coverage-final.json'
  ]
    .pipe $.remapIstanbul
      reports:
        'text': undefined
        'text-summary': undefined
        'lcovonly': 'coverage/ts-lcov.info'
        'json': 'coverage/ts-coverage-final.json'
        'html': 'coverage/ts-lcov-report'
      reportOpts:
        log: console.log

gulp.task 'coverage', (cb) ->
  $.runSequence 'coverage:ts'
    , cb

gulp.task 'clean', (cb) ->
  $.del [
    'dist'
    'coverage'
  ], cb

gulp.task 'watch', ->
  gulp.watch [
    'lib/**/*.ts'
    'test/**/*.ts'
  ], [
    'build:ts'
  ]

