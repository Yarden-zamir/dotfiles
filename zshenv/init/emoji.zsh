function random_emoji {
  local seed=${1:-$(date +%s)}
  EMOJI=(💩 🐦 🚀 🐞 🎨 🍕 🐭 👽 ☕️ 🔬 💀 🐷 🐼 🐶 🐸 🐧 🐳 🍔 🍣 🍻 🔮 💰 💎 💾 💜 🍪 🌞 🌍 🐌 🐓 🍄 )
  RANDOM=$(cksum <<< $seed | cut -f 1 -d ' ')
  echo -n "$EMOJI[$RANDOM%$#EMOJI+1]"
}
