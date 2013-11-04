module.exports = function(grunt) {
	// Configurable paths
	var yoConfig = {
		livereload : 35729,
		src : 'src',
		dist : 'dist',
		test : 'test/spec'
	};
	grunt.initConfig({

		yo : yoConfig,
		pkg : grunt.file.readJSON('package.json'),

		concat : {
			options : {
				separator : "\n\n"
			},
			dist : {
				src : ['src/_intro.js', 'src/main.js', 'src/_outro.js'],
				dest : 'dist/<%= pkg.name.replace(".js", "") %>.js'
			}
		},

		uglify : {
			options : {
				banner : '/*! <%= pkg.name.replace(".js", "") %> <%= grunt.template.today("dd-mm-yyyy") %> */\n'
			},
			dist : {
				files : {
					'dist/<%= pkg.name.replace(".js", "") %>.min.js' : ['<%= concat.dist.dest %>']
				}
			}
		},

		qunit : {
			files : ['test/*.html']
		},

		jshint : {
			files : ['dist/spa.js'],
			options : {
				globals : {
					console : true,
					module : true,
					document : true
				},
				jshintrc : '.jshintrc'
			}
		},

		coffee : {
			compile : {
				files : {
					'<%= yo.src %>/<%= pkg.name %>.js' : '<%= yo.src %>/<%= pkg.name %>.coffee',
					'<%= yo.dist %>/<%= pkg.name %>.js' : '<%= yo.src %>/<%= pkg.name %>.coffee'
				}
			}
		},

		watch : {
			files : ['<%= jshint.files %>'],
			tasks : ['coffee', 'jshint', 'qunit']
		}

	});

	grunt.loadNpmTasks('grunt-contrib-uglify');
	grunt.loadNpmTasks('grunt-contrib-jshint');
	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-qunit');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-concat');

	grunt.registerTask('test', ['jshint', 'qunit']);
	grunt.registerTask('default', ['concat', 'jshint', 'qunit', 'uglify']);

};
