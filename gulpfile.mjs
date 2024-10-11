import gulp from 'gulp';
import * as dartSass from 'sass';
import gulpSass from 'gulp-sass';
import autoprefixer from 'gulp-autoprefixer';
import cssnano from 'gulp-cssnano';

const sass = gulpSass(dartSass);

// Sass task
function sassTask() {
    return gulp.src('assets/scss/style.scss')
        .pipe(sass.sync({
            outputStyle: 'expanded',
            includePaths: ['node_modules', 'assets/scss']  // Add 'assets/scss' here
        }).on('error', sass.logError))
        .pipe(autoprefixer())
        .pipe(cssnano())
        .pipe(gulp.dest('assets/css'));
}

// Jekyll build task
function jekyllBuild(done) {
    console.log('Jekyll build started');
    return spawn('bundle', ['exec', 'jekyll', 'build'], { stdio: 'inherit' })
        .on('close', function() {
            console.log('Jekyll build completed');
            done();
        });
}

// BrowserSync task
function browserSyncServe(done) {
    browserSync.init({
        server: {
            baseDir: "."  // Serve from the root of your project
        },
        files: ['assets/css/**/*.css'],
        open: false
    });
    done();
}

// Watch task
function watch() {
    console.log('Watch task started');
    gulp.watch('assets/scss/**/*.scss', sassTask)
        .on('change', function(path) {
            console.log(`SCSS file changed: ${path}`);
        });
    gulp.watch(
        ['*.html', '_layouts/*.html', '_posts/*', '_includes/*', '**/*.md'],
        gulp.series(jekyllBuild, function(done) {
            browserSync.reload();
            done();
        })
    ).on('change', function(path) {
        console.log(`File changed: ${path}`);
    });
}

// Default task
export default sassTask;