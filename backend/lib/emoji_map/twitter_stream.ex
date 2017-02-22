defmodule EmojiMap.TwitterStream do
  @moduledoc """
  We get a Twitter Stream from locations within a bounding box. The
  bounding box is so large that the tweets can come from all over the world.
  This way we make sure that we only receive geo-tagged tweets. The reason for
  this is: It isn't possible to search for hundreds of different keywords at
  once. Plus location isn't a filter. So we find tweets from either the location
  OR matching the keyword. We have to filter ourself.
  """

  @doc """
  The main function of this module. Gets the stream, filters for empty
  coordinates, filters for emojis and then returns a simpler map.
  """
  def get_emoji_stream do
    # Sometimes the coordinates are still empty. Probably when a place was selected.
    # Could be refined
    ExTwitter.stream_filter([locations: "-168.8,-57.3,174.4,84.1"], :infinity)
    |> Stream.filter(fn(x) -> x.coordinates != nil || x.place != nil end)
    |> Stream.filter(&Regex.match?(emoji_pattern(), &1.text))
    |> Stream.map(fn(x) ->
      coordinates = cond do
        x.coordinates != nil ->
          x.coordinates |> Map.fetch!(:coordinates)
          |> coord_arr_to_str
        x.place != nil ->
          x.place |> get_coordinates_from_place
          |> coord_arr_to_str
        true -> nil
      end

      emoji = x.text |> reduce_to_emoji
      |> first_emoji

      %{emoji: emoji, text: x.text, screen_name: x.user.screen_name,
      profile_image_url: x.user.profile_image_url, coordinates: coordinates}
    end)
  end

  @doc """
  Not used for this example. Just get a Stream for a keyword.
  """
  def get_stream(track) do
    [track: track] |> ExTwitter.stream_filter(:infinity)
    |> Stream.map(fn(x) ->
      %{text: x.text}
    end)
  end

  def reduce_to_emoji(input_string) do
    tmp_string = Regex.replace(no_emoji_pattern(), input_string, "")
    Regex.replace(~r/[\s]+/, tmp_string, "")
  end

  @doc """
  Finds emojis. This is ugly, I know. But the thing is that emojis are
  encoded all over the place in UTF-8. There is not one range of UTF-8 characters
  for emojis. So I put them right in here. It works, so shut up or provide me
  with a better regex.
  """
  def emoji_pattern do
    ~r/[😀😃😄😁😆😅😂🤣☺️😊😇🙂🙃😉😌😍😘😗😙😚😋😜😝😛🤑🤗🤓😎🤡🤠😏😒😞😔😟😕🙁☹️😣😖😫😩😤😠😡😶😐😑😯😦😧😮😲😵😳😱😨😰😢😥🤤😭😓😪😴🙄🤔🤥😬🤐🤢🤧😷🤒🤕😈👿👹👺💩👻💀☠️👽👾🤖🎃😺😸😹😻😼😽🙀😿😾👐🙌👏🙏🤝👍👎👊✊🤛🤜🤞✌️🤘👌👈👉👆👇☝️✋🤚🖐🖖👋🤙💪🖕✍️🤳💅🖖💄💋👄👅👂👃👣👁👀🗣👤👥👶👦👧👨👩👱‍♀️👱👴👵👲👳‍♀️👳👮‍♀️👮👷‍♀️👷💂‍♀️💂🕵️‍♀️🕵️👩‍⚕️👨‍⚕️👩‍🌾👨‍🌾👩‍🍳👨‍🍳👩‍🎓👨‍🎓👩‍🎤👨‍🎤👩‍🏫👨‍🏫👩‍🏭👨‍🏭👩‍💻👨‍💻👩‍💼👨‍💼👩‍🔧👨‍🔧👩‍🔬👨‍🔬👩‍🎨👨‍🎨👩‍🚒👨‍🚒👩‍✈️👨‍✈️👩‍🚀👨‍🚀👩‍⚖️👨‍⚖️🤶🎅👸🤴👰🤵👼🤰🙇‍♀️🙇💁💁‍♂️🙅🙅‍♂️🙆🙆‍♂️🙋🙋‍♂️🤦‍♀️🤦‍♂️🤷‍♀️🤷‍♂️🙎🙎‍♂️🙍🙍‍♂️💇💇‍♂️💆💆‍♂️🕴💃🕺👯👯‍♂️🚶‍♀️🚶🏃‍♀️🏃👫👭👬💑👩‍❤️‍👩👨‍❤️‍👨💏👩‍❤️‍💋‍👩👨‍❤️‍💋‍👨👪👨‍👩‍👧👨‍👩‍👧‍👦👨‍👩‍👦‍👦👨‍👩‍👧‍👧👩‍👩‍👦👩‍👩‍👧👩‍👩‍👧‍👦👩‍👩‍👦‍👦👩‍👩‍👧‍👧👨‍👨‍👦👨‍👨‍👧👨‍👨‍👧‍👦👨‍👨‍👦‍👦👨‍👨‍👧‍👧👩‍👦👩‍👧👩‍👧‍👦👩‍👦‍👦👩‍👧‍👧👨‍👦👨‍👧👨‍👧‍👦👨‍👦‍👦👨‍👧‍👧👚👕👖👔👗👙👘👠👡👢👞👟👒🎩🎓👑⛑🎒👝👛👜💼👓🕶🌂☂️🐶🐱🐭🐹🐰🦊🐻🐼🐨🐯🦁🐮🐷🐽🐸🐵🙊🙉🙊🐒🐔🐧🐦🐤🐣🐥🦆🦅🦉🦇🐺🐗🐴🦄🐝🐛🦋🐌🐚🐞🐜🕷🕸🐢🐍🦎🦂🦀🦑🐙🦐🐠🐟🐡🐬🦈🐳🐋🐊🐆🐅🐃🐂🐄🦌🐪🐫🐘🦏🦍🐎🐖🐐🐏🐑🐕🐩🐈🐓🦃🕊🐇🐁🐀🐿🐾🐉🐲🌵🎄🌲🌳🌴🌱🌿☘️🍀🎍🎋🍃🍂🍁🍄🌾💐🌷🌹🥀🌻🌼🌸🌺🌎🌍🌏🌕🌖🌗🌘🌑🌒🌓🌔🌚🌝🌞🌛🌜🌙💫⭐️🌟✨⚡️🔥💥☄️☀️🌤⛅️🌥🌦🌈☁️🌧⛈🌩🌨☃️⛄️❄️🌬💨🌪🌫🌊💧💦☔️🍏🍎🍐🍊🍋🍌🍉🍇🍓🍈🍒🍑🍍🥝🥑🍅🍆🥒🥕🌽🌶🥔🍠🌰🥜🍯🥐🍞🥖🧀🥚🍳🥓🥞🍤🍗🍖🍕🌭🍔🍟🥙🌮🌯🥗🥘🍝🍜🍲🍥🍣🍱🍛🍚🍙🍘🍢🍡🍧🍨🍦🍰🎂🍮🍭🍬🍫🍿🍩🍪🥛🍼☕️🍵🍶🍺🍻🥂🍷🥃🍸🍹🍾🥄🍴🍽⚽️🏀🏈⚾️🎾🏐🏉🎱🏓🏸🥅🏒🏑🏏⛳️🏹🎣🥊🥋⛸🎿⛷🏂🏋️‍♀️🏋️🤺🤼‍♀️🤼‍♂️🤸‍♀️🤸‍♂️⛹️‍♀️⛹️🤾‍♀️🤾‍♂️🏌️‍♀️🏌️🏄‍♀️🏄🏊‍♀️🏊🤽‍♀️🤽‍♂️🚣‍♀️🚣🏇🚴‍♀️🚴🚵‍♀️🚵🎽🏅🎖🥇🥈🥉🏆🏵🎗🎫🎟🎪🤹‍♀️🤹‍♂️🎭🎨🎬🎤🎧🎼🎹🥁🎷🎺🎸🎻🎲🎯🎳🎮🎰🚗🚕🚙🚌🚎🏎🚓🚑🚒🚐🚚🚛🚜🛴🚲🛵🏍🚨🚔🚍🚘🚖🚡🚠🚟🚃🚋🚞🚝🚄🚅🚈🚂🚆🚇🚊🚉🚁🛩✈️🛫🛬🚀🛰💺🛶⛵️🛥🚤🛳⛴🚢⚓️🚧⛽️🚏🚦🚥🗺🗿🗽⛲️🗼🏰🏯🏟🎡🎢🎠⛱🏖🏝⛰🏔🗻🌋🏜🏕⛺️🛤🛣🏗🏭🏠🏡🏘🏚🏢🏬🏣🏤🏥🏦🏨🏪🏫🏩💒🏛⛪️🕌🕍🕋⛩🗾🎑🏞🌅🌄🌠🎇🎆🌇🌆🏙🌃🌌🌉🌁🆓📗📕⌚️📱📲💻⌨️🖥🖨🖱🖲🕹🗜💽💾💿📀📼📷📸📹🎥📽🎞📞☎️📟📠📺📻🎙🎚🎛⏱⏲⏰🕰⌛️⏳📡🔋🔌💡🔦🕯🗑🛢💸💵💴💶💷💰💳💎⚖️🔧🔨⚒🛠⛏🔩⚙️⛓🔫💣🔪🗡⚔️🛡🚬⚰️⚱️🏺🔮📿💈⚗️🔭🔬🕳💊💉🌡🚽🚰🚿🛁🛀🛎🔑🗝🚪🛋🛏🛌🖼🛍🛒🎁🎈🎏🎀🎊🎉🎎🏮🎐✉️📩📨📧💌📥📤📦🏷📪📫📬📭📮📯📜📃📄📑📊📈📉🗒🗓📆📅📇🗃🗳🗄📋📁📂🗂🗞📰📓📔📒📕📗📘📙📚📖🔖🔗📎🖇📐📏📌📍📌🎌🏳️🏴🏁🏳️‍🌈✂️🖊🖋✒️🖌🖍📝✏️🔍🔎🔏🔐🔒🔓❤️💛💚💙💜🖤💔❣️💕💞💓💗💖💘💝]/iu
  end

  @doc """
  Yes, I am lazy. Copy & paste plus inversion. Could be done better and is
  definitely not DRY.
  """
  def no_emoji_pattern do
    ~r/[^😀😃😄😁😆😅😂🤣☺️😊😇🙂🙃😉😌😍😘😗😙😚😋😜😝😛🤑🤗🤓😎🤡🤠😏😒😞😔😟😕🙁☹️😣😖😫😩😤😠😡😶😐😑😯😦😧😮😲😵😳😱😨😰😢😥🤤😭😓😪😴🙄🤔🤥😬🤐🤢🤧😷🤒🤕😈👿👹👺💩👻💀☠️👽👾🤖🎃😺😸😹😻😼😽🙀😿😾👐🙌👏🙏🤝👍👎👊✊🤛🤜🤞✌️🤘👌👈👉👆👇☝️✋🤚🖐🖖👋🤙💪🖕✍️🤳💅🖖💄💋👄👅👂👃👣👁👀🗣👤👥👶👦👧👨👩👱‍♀️👱👴👵👲👳‍♀️👳👮‍♀️👮👷‍♀️👷💂‍♀️💂🕵️‍♀️🕵️👩‍⚕️👨‍⚕️👩‍🌾👨‍🌾👩‍🍳👨‍🍳👩‍🎓👨‍🎓👩‍🎤👨‍🎤👩‍🏫👨‍🏫👩‍🏭👨‍🏭👩‍💻👨‍💻👩‍💼👨‍💼👩‍🔧👨‍🔧👩‍🔬👨‍🔬👩‍🎨👨‍🎨👩‍🚒👨‍🚒👩‍✈️👨‍✈️👩‍🚀👨‍🚀👩‍⚖️👨‍⚖️🤶🎅👸🤴👰🤵👼🤰🙇‍♀️🙇💁💁‍♂️🙅🙅‍♂️🙆🙆‍♂️🙋🙋‍♂️🤦‍♀️🤦‍♂️🤷‍♀️🤷‍♂️🙎🙎‍♂️🙍🙍‍♂️💇💇‍♂️💆💆‍♂️🕴💃🕺👯👯‍♂️🚶‍♀️🚶🏃‍♀️🏃👫👭👬💑👩‍❤️‍👩👨‍❤️‍👨💏👩‍❤️‍💋‍👩👨‍❤️‍💋‍👨👪👨‍👩‍👧👨‍👩‍👧‍👦👨‍👩‍👦‍👦👨‍👩‍👧‍👧👩‍👩‍👦👩‍👩‍👧👩‍👩‍👧‍👦👩‍👩‍👦‍👦👩‍👩‍👧‍👧👨‍👨‍👦👨‍👨‍👧👨‍👨‍👧‍👦👨‍👨‍👦‍👦👨‍👨‍👧‍👧👩‍👦👩‍👧👩‍👧‍👦👩‍👦‍👦👩‍👧‍👧👨‍👦👨‍👧👨‍👧‍👦👨‍👦‍👦👨‍👧‍👧👚👕👖👔👗👙👘👠👡👢👞👟👒🎩🎓👑⛑🎒👝👛👜💼👓🕶🌂☂️🐶🐱🐭🐹🐰🦊🐻🐼🐨🐯🦁🐮🐷🐽🐸🐵🙊🙉🙊🐒🐔🐧🐦🐤🐣🐥🦆🦅🦉🦇🐺🐗🐴🦄🐝🐛🦋🐌🐚🐞🐜🕷🕸🐢🐍🦎🦂🦀🦑🐙🦐🐠🐟🐡🐬🦈🐳🐋🐊🐆🐅🐃🐂🐄🦌🐪🐫🐘🦏🦍🐎🐖🐐🐏🐑🐕🐩🐈🐓🦃🕊🐇🐁🐀🐿🐾🐉🐲🌵🎄🌲🌳🌴🌱🌿☘️🍀🎍🎋🍃🍂🍁🍄🌾💐🌷🌹🥀🌻🌼🌸🌺🌎🌍🌏🌕🌖🌗🌘🌑🌒🌓🌔🌚🌝🌞🌛🌜🌙💫⭐️🌟✨⚡️🔥💥☄️☀️🌤⛅️🌥🌦🌈☁️🌧⛈🌩🌨☃️⛄️❄️🌬💨🌪🌫🌊💧💦☔️🍏🍎🍐🍊🍋🍌🍉🍇🍓🍈🍒🍑🍍🥝🥑🍅🍆🥒🥕🌽🌶🥔🍠🌰🥜🍯🥐🍞🥖🧀🥚🍳🥓🥞🍤🍗🍖🍕🌭🍔🍟🥙🌮🌯🥗🥘🍝🍜🍲🍥🍣🍱🍛🍚🍙🍘🍢🍡🍧🍨🍦🍰🎂🍮🍭🍬🍫🍿🍩🍪🥛🍼☕️🍵🍶🍺🍻🥂🍷🥃🍸🍹🍾🥄🍴🍽⚽️🏀🏈⚾️🎾🏐🏉🎱🏓🏸🥅🏒🏑🏏⛳️🏹🎣🥊🥋⛸🎿⛷🏂🏋️‍♀️🏋️🤺🤼‍♀️🤼‍♂️🤸‍♀️🤸‍♂️⛹️‍♀️⛹️🤾‍♀️🤾‍♂️🏌️‍♀️🏌️🏄‍♀️🏄🏊‍♀️🏊🤽‍♀️🤽‍♂️🚣‍♀️🚣🏇🚴‍♀️🚴🚵‍♀️🚵🎽🏅🎖🥇🥈🥉🏆🏵🎗🎫🎟🎪🤹‍♀️🤹‍♂️🎭🎨🎬🎤🎧🎼🎹🥁🎷🎺🎸🎻🎲🎯🎳🎮🎰🚗🚕🚙🚌🚎🏎🚓🚑🚒🚐🚚🚛🚜🛴🚲🛵🏍🚨🚔🚍🚘🚖🚡🚠🚟🚃🚋🚞🚝🚄🚅🚈🚂🚆🚇🚊🚉🚁🛩✈️🛫🛬🚀🛰💺🛶⛵️🛥🚤🛳⛴🚢⚓️🚧⛽️🚏🚦🚥🗺🗿🗽⛲️🗼🏰🏯🏟🎡🎢🎠⛱🏖🏝⛰🏔🗻🌋🏜🏕⛺️🛤🛣🏗🏭🏠🏡🏘🏚🏢🏬🏣🏤🏥🏦🏨🏪🏫🏩💒🏛⛪️🕌🕍🕋⛩🗾🎑🏞🌅🌄🌠🎇🎆🌇🌆🏙🌃🌌🌉🌁🆓📗📕⌚️📱📲💻⌨️🖥🖨🖱🖲🕹🗜💽💾💿📀📼📷📸📹🎥📽🎞📞☎️📟📠📺📻🎙🎚🎛⏱⏲⏰🕰⌛️⏳📡🔋🔌💡🔦🕯🗑🛢💸💵💴💶💷💰💳💎⚖️🔧🔨⚒🛠⛏🔩⚙️⛓🔫💣🔪🗡⚔️🛡🚬⚰️⚱️🏺🔮📿💈⚗️🔭🔬🕳💊💉🌡🚽🚰🚿🛁🛀🛎🔑🗝🚪🛋🛏🛌🖼🛍🛒🎁🎈🎏🎀🎊🎉🎎🏮🎐✉️📩📨📧💌📥📤📦🏷📪📫📬📭📮📯📜📃📄📑📊📈📉🗒🗓📆📅📇🗃🗳🗄📋📁📂🗂🗞📰📓📔📒📕📗📘📙📚📖🔖🔗📎🖇📐📏📌📍📌🎌🏳️🏴🏁🏳️‍🌈✂️🖊🖋✒️🖌🖍📝✏️🔍🔎🔏🔐🔒🔓❤️💛💚💙💜🖤💔❣️💕💞💓💗💖💘💝]/iu
  end

  def first_emoji(input_string) do
    input_string |> String.codepoints |> hd
  end

  @doc """
  Turn array with float numbers from Twitter API into String
  """
  def coord_arr_to_str(input_arr) do
    input_arr
    |> Enum.map(fn(x) -> "#{x}" end)
    |> Enum.join(",")
  end

  @doc """
  Places from the Twitter API are not a single point but a bouding box. For easy
  use we will just use the first coordinates. To find out more check here:
  https://dev.twitter.com/overview/api/tweets
  """
  def get_coordinates_from_place(%{bounding_box: %{coordinates: [bounding_box]}}) do
    bounding_box |> hd
  end

end
