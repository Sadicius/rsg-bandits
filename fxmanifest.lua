fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rsg-bandits'
version '1.0.2'

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

dependencies {
    'ox_lib',
    'rsg-core',
}

lua54 'yes'
