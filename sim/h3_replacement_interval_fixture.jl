using TOML

"""Read the ratified H3 replacement fixture without constructing a fit."""
const H3_REPLACEMENT_INTERVAL_FIXTURE = normpath(joinpath(
    @__DIR__, "..", "test", "fixtures", "h3_replacement_interval", "fixture.toml",
))

function h3_replacement_interval_fixture()
    return TOML.parsefile(H3_REPLACEMENT_INTERVAL_FIXTURE)
end
