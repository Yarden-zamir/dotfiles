function random_emoji {
  EMOJI=(💩 🐦 🚀 🐞 🎨 🍕 🐭 👽 ☕️ 🔬 💀 🐷 🐼 🐶 🐸 🐧 🐳 🍔 🍣 🍻 🔮 💰 💎 💾 💜 🍪 🌞 🌍 🐌 🐓 🍄 )
  RANDOM=$(cksum <<< $1 | cut -f 1 -d ' ')
  echo -n "$EMOJI[$RANDOM%$#EMOJI+1]"
}
