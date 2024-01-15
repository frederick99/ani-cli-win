
$agent = "Mozilla/5.0 (Windows NT 6.1; Win64; rv:109.0) Gecko/20100101 Firefox/109.0"
$allanime_base = "https://allanime.to"
$allanime_api = "https://api.allanime.day"
$mode = "sub"
$quality = "best"
$query = $args[0]

function search_anime($query)
{
    $search_gql = 'query(        $search: SearchInput        $limit: Int        $page: Int        $translationType: VaildTranslationTypeEnumType        $countryOrigin: VaildCountryOriginEnumType    ) {    shows(        search: $search        limit: $limit        page: $page        translationType: $translationType        countryOrigin: $countryOrigin    ) {        edges {            _id name availableEpisodes __typename       }    }}'

    $res = curl.exe -e "$allanime_base" -s -G "${allanime_api}/api" --data-urlencode "variables={`"search`":{`"allowAdult`":false,`"allowUnknown`":false,`"query`":`"$query`"},`"limit`":40,`"page`":1,`"translationType`":`"$mode`",`"countryOrigin`":`"ALL`"}" --data-urlencode "query=$search_gql" -A "$agent"
    # $res = '{"data":{"shows":{"edges":[{"_id":"AMBPQtBTFpnMXwjDA","name":"Haikyuu!!: vs. \"Akaten\"","availableEpisodes":{"sub":1,"dub":0,"raw":0},"__typename":"Show"},{"_id":"qwatQgrWFivocSTK7","name":"Haikyuu!!: Lev Kenzan!","availableEpisodes":{"sub":1,"dub":0,"raw":0},"__typename":"Show"},{"_id":"yu3mj35vbAxzaa3sj","name":"Haikyuu!! Quest Picture Drama","availableEpisodes":{"sub":3,"dub":0,"raw":0},"__typename":"Show"},{"_id":"wZs5ufX8p7wqr95Ru","name":"Haikyuu!!: Tokushuu! Haru-kou Volley ni Kaketa Seishun","availableEpisodes":{"sub":1,"dub":0,"raw":0},"__typename":"Show"},{"_id":"XNpYGuHcQXEqRDJtA","name":"Haikyuu!! TO THE TOP 2","availableEpisodes":{"sub":12,"dub":12,"raw":0},"__typename":"Show"},{"_id":"ShATn3dfoRYndktgj","name":"Haikyuu!! Movie 2: Shousha to Haisha","availableEpisodes":{"sub":1,"dub":0,"raw":0},"__typename":"Show"},{"_id":"ypWu2CdBANazaJXDS","name":"Haikyuu!! Movie 1: Owari to Hajimari","availableEpisodes":{"sub":1,"dub":0,"raw":0},"__typename":"Show"},{"_id":"A7dAR9Bi5F692uC8q","name":"Haikyuu!!: To the Top","availableEpisodes":{"sub":14,"dub":13,"raw":0},"__typename":"Show"},{"_id":"sfcBN5BhXC8or8BZk","name":"Haikyuu!! Ningyou Anime","availableEpisodes":{"sub":3,"dub":0,"raw":0},"__typename":"Show"},{"_id":"pni6s7z49QY5uRKi2","name":"Haikyuu!!: Riku vs. Kuu","availableEpisodes":{"sub":2,"dub":2,"raw":0},"__typename":"Show"},{"_id":"jtez849Sbh9CTBQqX","name":"Haikyuu!! Movie 4: Concept no Tatakai","availableEpisodes":{"sub":1,"dub":0,"raw":0},"__typename":"Show"},{"_id":"5SZ2ZySk5ZmcmQjDF","name":"Haikyuu!! Movie 3: Sainou to Sense","availableEpisodes":{"sub":1,"dub":0,"raw":0},"__typename":"Show"},{"_id":"rgrmNQsNwfrFtnjtY","name":"Haikyuu!!: Karasuno Koukou vs. Shiratorizawa Gakuen Koukou","availableEpisodes":{"sub":10,"dub":10,"raw":0},"__typename":"Show"},{"_id":"uwPLQNraQPTWFXPW6","name":"Haikyuu!! Season 2","availableEpisodes":{"sub":25,"dub":25,"raw":0},"__typename":"Show"},{"_id":"tefbTETHpYi8DDwci","name":"Haikyuu!!","availableEpisodes":{"sub":25,"dub":25,"raw":0},"__typename":"Show"}]}}}'
    (
        $res
        | ConvertFrom-Json
        | Select-Object -ExpandProperty data
        | Select-Object -ExpandProperty shows
        | Select-Object -ExpandProperty edges
        | Foreach-Object { $index = 1 } {
            [PSCustomObject] @{ Index = $index;
                                Id = $_._id;
                                Name = $_.name;
                                Sub = $_.availableEpisodes.sub };
            $index++
        }
    )
}

function episodes_list($id) {
    $episodes_list_gql = 'query ($showId: String!) {    show(        _id: $showId    ) {        _id availableEpisodesDetail    }}'

    $res = curl.exe -e "$allanime_base" -s -G "${allanime_api}/api" --data-urlencode "variables={`"showId`":`"$id`"}" --data-urlencode "query=$episodes_list_gql" -A "$agent"
    # $res = '{"data":{"show":{"_id":"tefbTETHpYi8DDwci","availableEpisodesDetail":{"sub":["25","24","23","22","21","20","19","18","17","16","15","14","13","12","11","10","9","8","7","6","5","4","3","2","1"],"dub":["25","24","23","22","21","20","19","18","17","16","15","14","13","12","11","10","9","8","7","6","5","4","3","2","1"],"raw":[]}}}}'
    (
        $res
        | ConvertFrom-Json
        | Select-Object -ExpandProperty data
        | Select-Object -ExpandProperty show
        | Select-Object -ExpandProperty availableEpisodesDetail
        | Select-Object -ExpandProperty sub
        | Sort-Object -Property { try { [int]$_ } catch { [int]::MaxValue } }
    )
}

# extract the video links from reponse of embed urls, extract mp4 links form m3u8 lists
function get_links($decrypted) {
    try {
        $res = curl.exe -e "$allanime_base" -s "https://embed.ssbcontent.site$decrypted" -A "$agent"
    }
    catch {
        $decrypted | Write-Host -ForegroundColor Red
        return
    }
    # $res = '{"links":[{"link":"https://www081.vipanicdn.net/streamhls/e4a54addecbdf175db3315b5a5a6ba80/ep.5.1703913385.m3u8","hls":true,"mp4":false,"resolutionStr":"hls P","priority":3},{"link":"https://www081.anifastcdn.info/videos/hls/QEyG2Il9d1HWGfgV8mfciQ/1705293485/43351/e4a54addecbdf175db3315b5a5a6ba80/ep.5.1703913385.m3u8","hls":true,"mp4":false,"resolutionStr":"HLS1","priority":2},{"link":"https://workfields.maverickki.lol/7d2473746a243c246e727276753c2929717171363e372867686f60677572656268286f68606929706f62636975296e6a752957437f41344f6a3f62374e51416061503e6b60656f572937313633343f35323e33293235353337296332673332676262636564626037313362643535373364336733673064673e36296376283328373136353f3735353e33286b35733e242a2476677475634e6a75243c727473632a2462677263243c373136333431303e36363636367b","hls":true,"resolutionStr":"Alt","src":"https://workfields.maverickki.lol/7d2473746a243c246e727276753c2929717171363e372867686f60677572656268286f68606929706f62636975296e6a752957437f41344f6a3f62374e51416061503e6b60656f572937313633343f35323e33293235353337296332673332676262636564626037313362643535373364336733673064673e36296376283328373136353f3735353e33286b35733e242a2476677475634e6a75243c727473632a2462677263243c373136333431303e36363636367b","priority":1}]}'
    # $res | sed 's|},{|\n|g' | sed -nE 's|.*link":"([^"]*)".*"resolutionStr":"([^"]*)".*|\2 >\1|p;s|.*hls","url":"([^"]*)".*"hardsub_lang":"en-US".*|\1|p'

    $links = (
        $res
        | ConvertFrom-Json
        | Select-Object -ExpandProperty links
        # | Foreach-Object { [PSCustomObject] @{ Resolution = $_.resolutionStr; Link = $_.link } }
        | Foreach-Object { $_.link }
    )

    $result = @()

    foreach ($link in $links) {
        if ($link.contains('vipanicdn') -or $link.contains('anifastcdn')) {
            if ($link.contains("original.m3u")) {
                $link
            } else {
                $extract_link = $link
                $relative_link = $extract_link -replace '[^/]*$', ''
                $response = curl.exe -e "$allanime_base" -s "$extract_link" -A "$agent"
#                 $response = '#EXTM3U
# #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=107546,RESOLUTION=640x360,NAME="360p"
# ep.5.1703913385.360.m3u8
# #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=177113,RESOLUTION=854x480,NAME="480p"
# ep.5.1703913385.480.m3u8
# #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=405534,RESOLUTION=1280x720,NAME="720p"
# ep.5.1703913385.720.m3u8
# #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=1065417,RESOLUTION=1920x1080,NAME="1080p"
# ep.5.1703913385.1080.m3u8'

                $parsed = ($response
                            | sed 's|^#.*x||g; s|,.*||g; /^#/d; $!N; s|\n| >|'
                            | sed "s|>|${relative_link}|g")
                $result += $parsed | ForEach-Object { [PSCustomObject] @{
                                                        Quality = [int]$_.split(' ')[0];
                                                        Link = $_.split(' ')[1] } }
            }
        } else {
            $result += [PSCustomObject] @{
                Quality = [int]::MinValue;
                Link = $link }
        }

        # Write-Host "`e[1;32m$provider_name`e[0m Links Fetched"
    }

    $result
}

function select_quality($links, $quality) {
    switch ($quality) {
        'best'  { $result = $links | Select-Object -First 1 }
        'worst' { $result = $links | Where-Object { $_.Quality -ne [int]::MinValue } | Select-Object -Last 1 }
        default { $result = $links | Where-Object { $_.Quality -eq $quality } | Select-Object -First 1 }
    }

    if ($null -eq $result) {
        Write-Host "Specified quality not found, defaulting to best"
        $result = $links | Select-Object -First 1
    }

    $result.Link
}

function decrypt_allanime($digest) {
    $sb = New-Object -TypeName "System.Text.StringBuilder";
    $hexs = $digest -split '(..)' | Where-Object { $_ }

    foreach ($hex in $hexs) {
        $dec = [Convert]::ToInt32($hex, 16)
        $xor = $dec -bxor 56
        $oct = [Convert]::ToString($xor, 8).PadLeft(3, '0')
        [void]$sb.Append("\" + $oct)
    }

    printf.exe $sb.ToString()
}

function generate_link($provider) {
    switch ($provider.SourceName) {
        'Default' { $provider_name = "wixmp"      } # wixmp(default)(m3u8)(multi) -> (mp4)(multi)
        'Sak'     { $provider_name = "dropbox"    } # dropbox(mp4)(single)
        'Kir'     { $provider_name = "wetransfer" } # wetransfer(mp4)(single)
        'S-mp4'   { $provider_name = "sharepoint" } # sharepoint(mp4)(single)
        'Luf-mp4' { $provider_name = "gogoanime"  } # gogoanime(m3u8)(multi)
        # default   { throw "Unknown provider: $provider" }
    }
    $provider_id = decrypt_allanime $provider.SourceUrl | sed "s/\/clock/\/clock\.json/"
    # echo "PID: [$provider_id]"
    if ($provider_id) {
        get_links "$provider_id"
    }
}

function get_episode_url($id, $ep_no, $mode) {
    # get the embed urls of the selected episode
    $episode_embed_gql = 'query ($showId: String!, $translationType: VaildTranslationTypeEnumType!, $episodeString: String!) {    episode(        showId: $showId        translationType: $translationType        episodeString: $episodeString    ) {        episodeString sourceUrls    }}'

    $res = curl.exe -e "$allanime_base" -s -G "${allanime_api}/api" --data-urlencode "variables={`"showId`":`"$id`",`"translationType`":`"$mode`",`"episodeString`":`"$ep_no`"}" --data-urlencode "query=$episode_embed_gql" -A "$agent"
    # $res = '{"data":{"episode":{"episodeString":"5","sourceUrls":[{"sourceUrl":"--175948514e4c4f57175b54575b5307515c050f5c0a0c0f0b0f0c0e590a0c0b5b0a0c0e5d0f0a0f0a0f0e0f0d0b5b0a010a010e0b0e5a0e0c0f0a0e0f0e5c0f0b0a000f0e0f0c0e010a010f0d0f0a0f0c0e0b0e0f0e5a0e5e0e000e090a000f0e0e5d0f0e0b010e5e0e0a0b5a0c000c0a0c5a0f5b0c000d0a0c0b0b5a0a080f0a0e5e0f0a0e590e0b0b5a0c5d0e0f0e5e0e5c0f5e0f0b0f0b0a0b0b0c0b0f0a0b0b0c0b0f0a080f0a0f5e0f0e0e0b0f0d0f0b0e0c0b5a0d0d0d0b0c0c0a080f0d0f0b0e0c0b5a0e0b0f5e0c5b0e590e0c0e5e0c5e0b080e0c0e000d080f0d0e0c0c0d0f090e5e0d5b0d5d0c5a0e5e0c010e5a0b0b0b0f0e0c0c090f5d0b5e0a080e0d0e010f080e0b0f0c0b5a0e0f0d090b0f0e5d0d5b0b0c0d080f5b0c590b0d0c000f090e0d0e5a0e590f0b0d5b0f5e0b5e0c5e0d5e0d090e590f0c0e0b0d5d0d080b0f0c590e5a0f0e0f090d5b0f090b5a0b5a0a0c0a590a0c0f0d0f0a0f0c0e0b0e0f0e5a0e0b0f0c0c5e0e0a0a0c0b5b0a0c0f080e5e0e0a0e0b0e010f0d0f0a0f0c0e0b0e0f0e5a0e5e0e010a0c0a590a0c0e0a0e0f0f0a0e0b0a0c0b5b0a0c0b0c0b0e0b0c0b0a0a5a0b0e0b0f0a5a0b0f0b0a0d0a0b0c0b0c0b5b0b0b0b5e0b5b0b0e0b0e0a000b0e0b0e0b0e0d5b0a0c0f5a1e4a5d5e5d4a5d4a05","priority":7.7,"sourceName":"Luf-mp4","type":"iframe","className":"","streamerId":"allanime"},{"sourceUrl":"https://embtaku.pro/streaming.php?id=NDMzNTE=&title=Haikyuu%21%21&typesub=SUB&sub=eyJlbiI6bnVsbCwiZXMiOm51bGx9&cover=aW1hZ2VzL3NwcmluZy9IYWlreXV1LmpwZw==","priority":4,"sourceName":"Vid-mp4","type":"iframe","className":"","streamerId":"allanime","downloads":{"sourceName":"Gl","downloadUrl":"https://embtaku.pro/download?id=NDMzNTE=&title=Haikyuu%21%21&typesub=SUB&sub=eyJlbiI6bnVsbCwiZXMiOm51bGx9&cover=aW1hZ2VzL3NwcmluZy9IYWlreXV1LmpwZw==&sandbox=allow-forms%20allow-scripts%20allow-same-origin%20allow-downloads"}},{"sourceUrl":"--175948514e4c4f57175b54575b5307515c050f5c0a0c0f0b0f0c0e590a0c0b5b0a0c0a010e5a0e0b0e0a0e5e0e0f0b0b0a010f080e5e0e0a0e0b0e010f0d0a010f0a0e0b0e080e0c0d0a0c0b0d0a0c5d0f0e0d5e0e5e0b5d0c0a0c0a0f090e0d0e5e0a010f0d0f0b0e0c0a010b0b0a0c0a590a0c0f0d0f0a0f0c0e0b0e0f0e5a0e0b0f0c0c5e0e0a0a0c0b5b0a0c0c0a0f0c0e010f0e0e0c0e010f5d0a0c0a590a0c0e0a0e0f0f0a0e0b0a0c0b5b0a0c0b0c0b0e0b0c0b0a0a5a0b0e0b0f0a5a0b0f0b0a0d0a0b0c0b0c0b5b0b0b0b5e0b5b0b0e0b0e0a000b0e0b0e0b0e0d5b0a0c0a590a0c0f0a0f0c0e0f0e000f0d0e590e0f0f0a0e5e0e010e000d0a0f5e0f0e0e0b0a0c0b5b0a0c0f0d0f0b0e0c0a0c0a590a0c0e5c0e0b0f5e0a0c0b5b0a0c0e0b0f0e0a5a0a010e5a0e0b0e0a0e5e0e0f0b0b0a010f080e5e0e0a0e0b0e010f0d0a010f0a0e0b0e080e0c0d0a0c0b0d0a0c5d0f0e0d5e0e5e0b5d0c0a0c0a0f090e0d0e5e0a010f0d0f0b0e0c0a010b0b0a0c0f5a","priority":7,"sourceName":"Sak","type":"iframe","className":"","streamerId":"allanime"},{"sourceUrl":"--504c4c484b0217174c5757544b165e594b4c0c4b485d5d5c164a4b4e481717555d5c51590d174e515c5d574b174c5d5e5a6c7d6c70486151007c7c4f5b51174b4d5a170d","priority":7.9,"sourceName":"Yt-mp4","type":"player","className":"","streamerId":"allanime"},{"sourceUrl":"https://streamlare.com/e/7vjPWlqKqGvD34JK","priority":3,"sourceName":"Sl-mp4","type":"iframe","className":"text-danger","streamerId":"allanime","downloads":{"sourceName":"Sl","downloadUrl":"https://streamlare.com/v/7vjPWlqKqGvD34JK"}},{"sourceUrl":"https://ok.ru/videoembed/3673260427922","priority":3.5,"sourceName":"Ok","type":"iframe","sandbox":"allow-forms allow-scripts allow-same-origin","className":"text-info","streamerId":"allanime"},{"sourceUrl":"https://streamsb.net/e/yl41wmt45ubs.html","priority":5.5,"sourceName":"Ss-Hls","type":"iframe","className":"text-danger","streamerId":"allanime","downloads":{"sourceName":"StreamSB","downloadUrl":"https://streamsb.net/d/yl41wmt45ubs.html&sandbox=allow-forms%20allow-scripts%20allow-same-origin%20allow-downloads"}},{"sourceUrl":"https://mp4upload.com/embed-wby3pllr5sij.html","priority":4,"sourceName":"Mp4","type":"iframe","sandbox":"allow-forms allow-scripts allow-same-origin","className":"","streamerId":"allanime"},{"sourceUrl":"--175948514e4c4f57175b54575b5307515c050f5c0a0c0f0b0f0c0e590a0c0b5b0a0c0a010f0d0e5e0f0a0e0b0f0d0a010e0f0e000e5e0e5a0e0b0a010d0d0e5d0e0f0f0c0e0b0e0a0a0e0c0a0e010e0d0f0b0e5a0e0b0e000f0a0f0d0a010f0a0e0b0e080e0c0d0a0c0b0d0a0c5d0f0e0d5e0e5e0b5d0c0a0c0a0f090e0d0e5e0d010b0b0d010f0d0f0b0e0c0a000e5a0f0e0b0a0a0c0a590a0c0f0d0f0a0f0c0e0b0e0f0e5a0e0b0f0c0c5e0e0a0a0c0b5b0a0c0d0d0e5d0e0f0f0c0e0b0f0e0e010e5e0e000f0a0a0c0a590a0c0e0a0e0f0f0a0e0b0a0c0b5b0a0c0b0c0b0e0b0c0b0a0a5a0b0e0b0f0a5a0b0f0b0a0d0a0b0c0b0c0b5b0b0b0b5e0b5b0b0e0b0e0a000b0e0b0e0b0e0d5b0a0c0a590a0c0f0a0f0c0e0f0e000f0d0e590e0f0f0a0e5e0e010e000d0a0f5e0f0e0e0b0a0c0b5b0a0c0f0d0f0b0e0c0a0c0a590a0c0e5c0e0b0f5e0a0c0b5b0a0c0e0b0f0e0a5a0f0a0e0b0e080e0c0d0a0c0b0d0a0c5d0f0e0d5e0e5e0b5d0c0a0c0a0f090e0d0e5e0d010b0b0d010f0d0f0b0e0c0a0c0f5a","priority":7.4,"sourceName":"S-mp4","type":"iframe","className":"","streamerId":"allanime","downloads":{"sourceName":"S-mp4","downloadUrl":"https://blog.allanime.day/apivtwo/clock/download?id=7d2473746a243c2429756f7263752967686f6b6329556e6774636226426965736b6368727529726360645243524e765f6f3e424271656f593359757364286b7632242a2475727463676b63744f62243c24556e67746376696f6872242a2462677263243c24343634322b36372b37325234343c333f3c3636283636365c242a24626971686a696762243c727473637b"}},{"sourceUrl":"--175948514e4c4f57175b54575b5307515c050f5c0a0c0f0b0f0c0e590a0c0b5b0a0c0b0a0e0d0b0e0b0d0b090b080d010e0f0b0c0b0b0e080b090e0f0b0c0b090b5d0b0a0e0d0b0c0b0a0b080e0b0e0c0b5e0e0c0b5e0e0f0e0d0e0c0e0b0b0a0e0f0b0a0b0f0e0c0e0a0b0e0e0d0e0c0a0e0f590a0e0b0a0b090b0f0b5d0e0a0b080e0f0b090b5e0e0c0b0a0e0c0e0c0b0e0b0b0b080b0a0e0f0b0a0b0c0b0b0b0b0b0c0e0d0e0d0e0c0b5e0b0f0e0b0e0a0e0b0b080a0e0f590a0e0e5a0e0b0e0a0e5e0e0f0a010b0a0e0d0b0e0b0d0b090b080d010e0f0b0c0b0b0e080b090e0f0b0c0b090b5d0b0a0e0d0b0c0b0a0b080e0b0e0c0b5e0e0c0b5e0e0f0e0d0e0c0e0b0b0a0e0f0b0a0b0f0e0c0e0a0b0e0e0d0e0c0e080b0e0b0e0b0f0a000e5b0f0e0e090a0e0f590a0e0a590b0f0b0e0b5d0b0e0f0e0a590b090b0c0b0e0f0e0a590b0a0b5d0b0e0f0e0a590a0c0a590a0c0f0d0f0a0f0c0e0b0e0f0e5a0e0b0f0c0c5e0e0a0a0c0b5b0a0c0d090e5e0f5d0a0c0a590a0c0e0a0e0f0f0a0e0b0a0c0b5b0a0c0b0c0b0e0b0c0b0a0a5a0b0e0b0f0a5a0b0f0b0a0d0a0b0c0b0c0b5b0b0b0b5e0b5b0b0e0b0e0a000b0e0b0e0b0e0d5b0a0c0a590a0c0f0a0f0c0e0f0e000f0d0e590e0f0f0a0e5e0e010e000d0a0f5e0f0e0e0b0a0c0b5b0a0c0f0d0f0b0e0c0a0c0a590a0c0e5c0e0b0f5e0a0c0b5b0a0c0e0b0f0e0a5a0f0a0e0b0e080e0c0d0a0c0b0d0a0c5d0f0e0d5e0e5e0b5d0c0a0c0a0f090e0d0e5e0d010b0b0d010f0d0f0b0e0c0a0c0f5a","priority":8.5,"sourceName":"Default","type":"iframe","className":"text-info","streamerId":"allanime"},{"sourceUrl":"--175948514e4c4f57175b54575b5307515c050f5c0a0c0f0b0f0c0e590a0c0b5b0a0c0e5d0f0a0f0a0f0e0f0d0b5b0a010a010f0b0f0d0e0b0f0c0f0d0e0d0e590e010f0b0e0a0a000e0d0e010e5a0a010e0b0e5a0e0c0e0b0e0a0a5a0b0a0e0c0b0c0f080e090f0b0b0b0f0f0e0c0e5c0e5b0e0f0a000e5d0f0a0e5a0e590a0c0a590a0c0f0d0f0a0f0c0e0b0e0f0e5a0e0b0f0c0c5e0e0a0a0c0b5b0a0c0d0b0f0d0e0b0f0c0f080e5e0e0a0a0c0a590a0c0e0a0e0f0f0a0e0b0a0c0b5b0a0c0b0c0b0e0b0c0b0a0a5a0b0e0b0f0a5a0b0f0b0a0d0a0b0c0b0c0b5b0b0b0b5e0b5b0b0e0b0e0a000b0e0b0e0b0e0d5b0a0c0a590a0c0f0a0f0c0e0f0e000f0d0e590e0f0f0a0e5e0e010e000d0a0f5e0f0e0e0b0a0c0b5b0a0c0f0d0f0b0e0c0a0c0a590a0c0e5c0e0b0f5e0a0c0b5b0a0c0e0b0f0e0a5a0f0a0e0b0e080e0c0d0a0c0b0d0a0c5d0f0e0d5e0e5e0b5d0c0a0c0a0f090e0d0e5e0d010b0b0d010f0d0f0b0e0c0a0c0f5a","priority":1,"sourceName":"Uv-mp4","type":"iframe","className":"","streamerId":"allanime"}]}}}'

    # extract sourceUrl and sourceName from the embed urls
    $providers = (
        $res
        | ConvertFrom-Json
        | Select-Object -ExpandProperty 'data'
        | Select-Object -ExpandProperty 'episode'
        | Select-Object -ExpandProperty 'sourceUrls'
        | Where-Object { $_.sourceUrl.StartsWith("--") }
        | Foreach-Object { $index = 1 } {
            [PSCustomObject] @{ Index = $index;
                                SourceName = $_.sourceName;
                                SourceUrl = $_.sourceUrl.Substring(2) };
            $index++
        }
    )

    $links = @()
    foreach ($provider in $providers)
    {
        $links += generate_link $provider
    }

    $links = $links | Sort-Object -Property Quality -Descending
    $episode = select_quality $links $quality

    if ($null -eq $episode) { throw "Episode not released!" }
    $episode
}

function play_episode($episode_url) {
    & 'D:\Programs\VideoLAN\VLC\vlc.exe' --play-and-exit $episode_url
}

function nth($prompt, [switch]$no_echo, [parameter(ValueFromPipeline = $true)]$list ) {
    if (-NOT($no_echo)) { $list | Out-Host }
    $n = Read-Host "$prompt (1-$($list.Count))"
    $el = $list[$n - 1]

    if ($null -eq $el) {
        "Invalid index: $n" | Out-Host
        nth $prompt -no_echo $list
    } else {
        $el
    }
}

$animes = search_anime $query
$anime = ,$animes | nth "Select anime"

$eps = episodes_list $anime.Id
$ep = ,$eps | nth "Select episode" -no_echo

$episode_url = get_episode_url $anime.Id $ep "sub"
play_episode $episode_url
