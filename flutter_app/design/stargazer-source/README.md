# Stargazer Cat source art

The nine transparent source images in this folder were made with the built-in
image generation tool. The selected `meteor-observer-v2.png` concept sheet and
`meteor-observer-corrected-poses.png` were the visual references. The prompt
kept the base cat's navy fur, amber eyes, asymmetrical ears, cream markings,
starry teal beret, short constellation cape, and gold brooch consistent. Each
pose was requested as a separate isolated sprite with four anatomical limbs.

The focus pose was revised once to shorten the telescope and reduce its width
in the 88×96 dp home card. Guide points left toward the home card's text.

The export command uses nearest-neighbor sampling and retains alpha:

```sh
swiftc tool/export_stargazer_assets.swift -o /tmp/export_stargazer_assets
/tmp/export_stargazer_assets design/stargazer-source/idle.png assets/characters/cat_stargazer/v1/approved/idle.png
```

Other poses and decorations use the same export command. The generated images
are artwork drafts: inspect paw counts, eye/ear details, and pixel consistency
at app size before release.
