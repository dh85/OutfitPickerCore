import OutfitPickerCore
import OutfitPickerTestSupport
import Testing

struct ConfigBuilderTests {
    @Test func basicBuild() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.english)
            .build()

        #expect(config.root == "/test/path")
        #expect(config.language == "en")
        #expect(config.knownCategories.isEmpty)
        #expect(config.excludedCategories.isEmpty)
    }

    @Test func missingRoot() {
        #expect(throws: ConfigError.missingRoot) {
            try ConfigBuilder().build()
        }
    }

    @Test func missingLanguage() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .build()

        #expect(config.root == "/test/path")
        #expect(config.language == "en")
    }

    @Test func excludeCategories() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.french)
            .exclude(categories: ["downloads", "documents"])
            .build()

        #expect(config.excludedCategories.contains("downloads"))
        #expect(config.excludedCategories.contains("documents"))
        #expect(config.excludedCategories.count == 2)
    }

    @Test func excludeCategory() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.french)
            .exclude(category: "downloads")
            .build()

        #expect(config.excludedCategories.contains("downloads"))
        #expect(config.excludedCategories.count == 1)
    }

    @Test func includeCategories() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.italian)
            .include(categories: ["casual", "formal"])
            .build()

        #expect(config.knownCategories.contains("casual"))
        #expect(config.knownCategories.contains("formal"))
        #expect(config.knownCategories.count == 2)
    }

    @Test func includeCategory() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.portuguese)
            .include(category: "summer")
            .build()

        #expect(config.knownCategories.contains("summer"))
        #expect(config.knownCategories.count == 1)
    }

    @Test func knownCategoriesWithStates() throws {
        let categories = [
            "casual": CategoryState.hasOutfits, "formal": CategoryState.empty,
        ]
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.german)
            .knownCategories(categories)
            .build()

        #expect(config.knownCategories.count == 2)
        #expect(config.knownCategories.contains("casual"))
        #expect(config.knownCategories.contains("formal"))
    }

    @Test func chaining() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.spanish)
            .exclude(category: "winter")
            .exclude(categories: ["formal", "party"])
            .include(category: "casual")
            .include(categories: ["summer", "spring"])
            .build()

        #expect(config.root == "/test/path")
        #expect(config.language == "es")
        #expect(config.excludedCategories.count == 3)
        #expect(config.knownCategories.count == 3)
    }

    @Test func allLanguages() throws {
        for language in SupportedLanguage.allCases {
            let config = try ConfigBuilder()
                .rootDirectory("/test/path")
                .language(language)
                .build()

            #expect(config.language == language.rawValue)
        }
    }

    @Test func builderReuse() throws {
        let builder = ConfigBuilder()
            .rootDirectory("/test/path")
            .language(.english)

        let config1 = try builder.exclude(category: "formal").build()
        let config2 = try builder.exclude(category: "casual").build()

        #expect(config1.excludedCategories.contains("formal"))
        #expect(config2.excludedCategories.contains("formal"))
        #expect(config2.excludedCategories.contains("casual"))
    }

    @Test func includeVariadic() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .include("a", "b", "c")
            .build()
        #expect(config.knownCategories == ["a", "b", "c"])
    }

    @Test func knownCategoriesSequence() throws {
        let seq = ["x", "y", "z"].lazy.map { $0 }  // any Sequence<String>
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .knownCategories(seq)
            .build()
        #expect(config.knownCategories == ["x", "y", "z"])
    }

    @Test func excludeVariadic_singleAndMultiple() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .exclude("downloads", "tmp", "backups")
            .build()

        #expect(config.excludedCategories == ["downloads", "tmp", "backups"])
    }

    @Test func excludeVariadic_withDuplicatesAndWhitespace() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .exclude("tmp", "tmp", " logs ")
            .build()

        #expect(config.excludedCategories.contains("tmp"))
        #expect(!config.excludedCategories.contains(" logs "))
        #expect(config.excludedCategories.contains("logs"))
        #expect(config.excludedCategories.count == 2)
    }

    @Test func excludeVariadic_worksAlongsideOtherExcludeAPIs() throws {
        let config = try ConfigBuilder()
            .rootDirectory("/test/path")
            .exclude(category: "formal")
            .exclude(categories: ["private"])
            .exclude("archive", "tmp")  // variadic under test
            .build()

        #expect(
            config.excludedCategories == [
                "formal", "private", "archive", "tmp",
            ]
        )
    }

    @Test func builderReuse_withVariadicExclude() throws {
        let builder = ConfigBuilder().rootDirectory("/test/path")

        let c1 = try builder.exclude("a", "b").build()
        let c2 = try builder.exclude("c").build()

        #expect(c1.excludedCategories == ["a", "b"])
        #expect(c2.excludedCategories == ["a", "b", "c"])  // reuse accumulates
    }
}
