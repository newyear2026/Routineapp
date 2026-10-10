package com.dayround.app

import android.graphics.Color
import android.graphics.RectF

/**
 * 팩마다 다른 홈 화면 위젯 모양.
 *
 * 위젯 코드는 팩 ID를 비교하지 않고 이 값만 읽는다. **팩 ID로 가르는 곳은
 * [forPack] 하나다** — 팩을 더하면 여기에 한 줄을 더하고, 빠뜨리면
 * `pack_spec_test.dart`가 잡는다. 앱 안 미리보기의 기준값은
 * `lib/theme/pack_skin_catalog.dart`에 있다.
 */
data class RoutineWidgetSkin(
    val ring: RingColors,
    val medium: MediumSkin,
    val variant: VariantSkin,
) {
    /** 원판 비트맵([RoutineWidgetRingBitmap])의 색. */
    data class RingColors(
        val dial: Int = Color.parseColor("#F3EDF9"),
        val dialOutline: Int = Color.parseColor("#221C42"),
        val surface: Int = Color.parseColor("#FFFFFF"),
        val track: Int = Color.parseColor("#E4DCFB"),
        val pointer: Int = Color.parseColor("#6744F4"),
        val hourLabel: Int = Color.parseColor("#221C42"),
        val tick: Int = Color.parseColor("#6A6489"),
        val tickAlphaMajor: Int = 87,
        val tickAlphaMinor: Int = 46,
        /** 가운데 «지금» 딱지의 글자와 테두리. */
        val centerLabelInk: Int = Color.parseColor("#6A6489"),
        val centerLabelSurface: Int = Color.parseColor("#F0E9D9"),
    )

    /** 링 위젯(`widget_routine_medium.xml`)에 입히는 리소스와 색. */
    data class MediumSkin(
        val background: Int,
        val badgeBackground: Int,
        /** [featuredMascot]이면 큰 후광 틀에, 아니면 작은 자리에 들어간다. */
        val mascot: Int,
        val featuredMascot: Boolean = false,
        /** 밤하늘 장면과 전용 글자 열을 쓴다. */
        val nightSky: Boolean = false,
        val decor: MediumDecor = MediumDecor.SKY,
        val title: Int = Color.parseColor("#191344"),
        val muted: Int = Color.parseColor("#6B6492"),
        val accent: Int = Color.parseColor("#643AF6"),
        val badgeText: Int = Color.parseColor("#FFFFFF"),
        val nowLabelBackground: Int = R.color.widget_label_surface,
        val nowLabelText: Int = Color.parseColor("#6A6489"),
    )

    enum class MediumDecor { SKY, GARDEN, FOREST, MOONCLOUD, DAWN, TEASHOP, SEASIDE, SNOWWALK, NONE }

    /** 타임라인·카드 위젯([RoutineWidgetVariantBitmap]). */
    data class VariantSkin(
        val style: VariantStyle,
        val pet: Int,
        val timelinePet: RectF,
        val cardsPet: RectF,
        val badgeFill: Int,
        val badgeText: Int = Color.WHITE,
        /** [VariantStyle.STANDARD]만 쓴다. 나머지 모양은 자기 장면을 직접 그린다. */
        val scene: StandardScene? = null,
    )

    /**
     * 변형 위젯의 그리기 방식. 기본 장면 위에 값만 바꿔 얹는 팩은 [STANDARD]를
     * 쓰고, 장면을 통째로 새로 그리는 팩은 자기 이름의 방식을 더한다.
     */
    enum class VariantStyle { STANDARD, STARGAZER, RABBIT, SQUIRREL, SHEEP, TEASHOP, SEASIDE, SNOWWALK }

    data class StandardScene(
        val background: Int,
        val nextPanelFill: Int,
        val nextPanelInner: Int,
        val nextIcon: Int,
        val divider: Int,
    )

    companion object {
        private val starlightCat = RoutineWidgetSkin(
            ring = RingColors(),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_cat,
                badgeBackground = R.drawable.widget_badge_bg,
                mascot = R.drawable.widget_cat,
            ),
            variant = VariantSkin(
                style = VariantStyle.STANDARD,
                pet = R.drawable.widget_variant_cat,
                timelinePet = RectF(464f, 45f, 633f, 187f),
                cardsPet = RectF(49f, 76f, 207f, 205f),
                badgeFill = Color.rgb(100, 58, 246),
                scene = StandardScene(
                    background = R.drawable.widget_bg_timeline_cat,
                    nextPanelFill = Color.rgb(237, 227, 255),
                    nextPanelInner = Color.rgb(212, 194, 246),
                    nextIcon = R.drawable.widget_moon,
                    divider = Color.rgb(200, 189, 238),
                ),
            ),
        )

        private val poodleGarden = RoutineWidgetSkin(
            ring = RingColors(),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_poodle,
                badgeBackground = R.drawable.widget_badge_bg_poodle,
                mascot = R.drawable.widget_poodle,
                decor = MediumDecor.GARDEN,
            ),
            variant = VariantSkin(
                style = VariantStyle.STANDARD,
                pet = R.drawable.widget_variant_poodle,
                timelinePet = RectF(485f, 39f, 618f, 186f),
                cardsPet = RectF(61f, 73f, 195f, 205f),
                badgeFill = Color.rgb(4, 145, 152),
                scene = StandardScene(
                    background = R.drawable.widget_bg_timeline_poodle,
                    nextPanelFill = Color.rgb(218, 250, 235),
                    nextPanelInner = Color.rgb(176, 227, 207),
                    nextIcon = R.drawable.widget_daisy,
                    divider = Color.rgb(161, 207, 188),
                ),
            ),
        )

        private val stargazerCat = RoutineWidgetSkin(
            ring = RingColors(
                dial = Color.parseColor("#0A3446"),
                dialOutline = Color.parseColor("#081F36"),
                track = Color.parseColor("#1D6A7C"),
                pointer = Color.parseColor("#F4C430"),
                hourLabel = Color.parseColor("#E0F2F0"),
                tick = Color.parseColor("#BCE4E8"),
                tickAlphaMajor = 180,
                tickAlphaMinor = 110,
                centerLabelInk = Color.parseColor("#476275"),
                centerLabelSurface = Color.parseColor("#FFE295"),
            ),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_stargazer,
                badgeBackground = R.drawable.widget_badge_bg_stargazer,
                mascot = R.drawable.widget_stargazer,
                featuredMascot = true,
                nightSky = true,
                decor = MediumDecor.NONE,
                title = Color.parseColor("#FFF9EA"),
                muted = Color.parseColor("#D6E6ED"),
                accent = Color.parseColor("#F4C430"),
                badgeText = Color.parseColor("#123041"),
                nowLabelBackground = R.drawable.widget_now_bg_stargazer,
                nowLabelText = Color.parseColor("#123041"),
            ),
            variant = VariantSkin(
                style = VariantStyle.STARGAZER,
                pet = R.drawable.widget_stargazer,
                timelinePet = RectF(464f, 45f, 633f, 187f),
                cardsPet = RectF(49f, 76f, 207f, 205f),
                badgeFill = Color.rgb(244, 196, 48),
                badgeText = Color.rgb(18, 48, 65),
            ),
        )

        private val postmanRabbit = RoutineWidgetSkin(
            ring = RingColors(
                dial = Color.parseColor("#FFE3D0"),
                dialOutline = Color.parseColor("#493330"),
                surface = Color.parseColor("#FFFCF3"),
                track = Color.parseColor("#C5E4CA"),
                pointer = Color.parseColor("#DB665E"),
            ),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_rabbit,
                badgeBackground = R.drawable.widget_badge_bg_rabbit,
                mascot = R.drawable.widget_rabbit,
                featuredMascot = true,
                decor = MediumDecor.DAWN,
                title = Color.parseColor("#493330"),
                muted = Color.parseColor("#80645C"),
                accent = Color.parseColor("#C5514A"),
            ),
            variant = VariantSkin(
                style = VariantStyle.RABBIT,
                pet = R.drawable.widget_variant_rabbit,
                timelinePet = RectF(464f, 20f, 633f, 188f),
                cardsPet = RectF(49f, 49f, 207f, 205f),
                badgeFill = Color.rgb(219, 102, 94),
            ),
        )

        private val explorerSquirrel = RoutineWidgetSkin(
            ring = RingColors(
                dial = Color.parseColor("#F6EBD6"),
                dialOutline = Color.parseColor("#3E3229"),
                surface = Color.parseColor("#FFFDF5"),
                track = Color.parseColor("#CDDEC1"),
                pointer = Color.parseColor("#718B51"),
                hourLabel = Color.parseColor("#3E3229"),
                tick = Color.parseColor("#746C5A"),
                centerLabelInk = Color.parseColor("#3E3229"),
                centerLabelSurface = Color.parseColor("#FFE5AE"),
            ),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_squirrel,
                badgeBackground = R.drawable.widget_badge_bg_squirrel,
                mascot = R.drawable.widget_squirrel,
                featuredMascot = true,
                decor = MediumDecor.FOREST,
                title = Color.parseColor("#3E3229"),
                muted = Color.parseColor("#746C5A"),
                accent = Color.parseColor("#718B51"),
            ),
            variant = VariantSkin(
                style = VariantStyle.SQUIRREL,
                pet = R.drawable.widget_variant_squirrel,
                timelinePet = RectF(464f, 20f, 633f, 188f),
                cardsPet = RectF(49f, 49f, 207f, 205f),
                badgeFill = Color.parseColor("#718B51"),
            ),
        )

        private val mooncloudSheep = RoutineWidgetSkin(
            ring = RingColors(
                dial = Color.parseColor("#E7ECFF"),
                dialOutline = Color.parseColor("#242548"),
                surface = Color.parseColor("#FFFCFF"),
                track = Color.parseColor("#CFC8F2"),
                pointer = Color.parseColor("#6577C8"),
                hourLabel = Color.parseColor("#242548"),
                tick = Color.parseColor("#626A92"),
                centerLabelInk = Color.parseColor("#242548"),
                centerLabelSurface = Color.parseColor("#FFF0C2"),
            ),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_sheep,
                badgeBackground = R.drawable.widget_badge_bg_sheep,
                mascot = R.drawable.widget_sheep,
                featuredMascot = true,
                decor = MediumDecor.MOONCLOUD,
                title = Color.parseColor("#242548"),
                muted = Color.parseColor("#626A92"),
                accent = Color.parseColor("#6577C8"),
            ),
            variant = VariantSkin(
                style = VariantStyle.SHEEP,
                pet = R.drawable.widget_variant_sheep,
                timelinePet = RectF(464f, 20f, 633f, 188f),
                cardsPet = RectF(49f, 49f, 207f, 205f),
                badgeFill = Color.parseColor("#6577C8"),
            ),
        )

        private val redPandaTeashop = RoutineWidgetSkin(
            ring = RingColors(
                dial = Color.parseColor("#F8EAD7"),
                dialOutline = Color.parseColor("#3D302D"),
                surface = Color.parseColor("#FFFDF6"),
                track = Color.parseColor("#C7DED4"),
                pointer = Color.parseColor("#376D68"),
                hourLabel = Color.parseColor("#3D302D"),
                tick = Color.parseColor("#776B65"),
                centerLabelInk = Color.parseColor("#3D302D"),
                centerLabelSurface = Color.parseColor("#FFE6B9"),
            ),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_redpanda,
                badgeBackground = R.drawable.widget_badge_bg_redpanda,
                mascot = R.drawable.widget_redpanda,
                featuredMascot = true,
                decor = MediumDecor.TEASHOP,
                title = Color.parseColor("#3D302D"),
                muted = Color.parseColor("#776B65"),
                accent = Color.parseColor("#376D68"),
            ),
            variant = VariantSkin(
                style = VariantStyle.TEASHOP,
                pet = R.drawable.widget_variant_redpanda,
                timelinePet = RectF(464f, 20f, 633f, 188f),
                cardsPet = RectF(49f, 49f, 207f, 205f),
                badgeFill = Color.parseColor("#376D68"),
            ),
        )

        private val otterSeaside = RoutineWidgetSkin(
            ring = RingColors(
                dial = Color.parseColor("#FFF1D7"),
                dialOutline = Color.parseColor("#29444A"),
                surface = Color.parseColor("#FFFDF5"),
                track = Color.parseColor("#D7F5F2"),
                pointer = Color.parseColor("#157F8E"),
                hourLabel = Color.parseColor("#29444A"),
                tick = Color.parseColor("#59777A"),
                centerLabelInk = Color.parseColor("#29444A"),
                centerLabelSurface = Color.parseColor("#FFE7C3"),
            ),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_otter,
                badgeBackground = R.drawable.widget_badge_bg_otter,
                mascot = R.drawable.widget_otter,
                featuredMascot = true,
                decor = MediumDecor.SEASIDE,
                title = Color.parseColor("#29444A"),
                muted = Color.parseColor("#59777A"),
                accent = Color.parseColor("#157F8E"),
            ),
            variant = VariantSkin(
                style = VariantStyle.SEASIDE,
                pet = R.drawable.widget_variant_otter,
                timelinePet = RectF(464f, 20f, 633f, 188f),
                cardsPet = RectF(49f, 49f, 207f, 205f),
                badgeFill = Color.parseColor("#157F8E"),
            ),
        )

        private val penguinSnowWalk = RoutineWidgetSkin(
            ring = RingColors(
                dial = Color.parseColor("#F0F4FF"),
                dialOutline = Color.parseColor("#2D344F"),
                surface = Color.WHITE,
                track = Color.parseColor("#D2DCFA"),
                pointer = Color.parseColor("#6577C7"),
                hourLabel = Color.parseColor("#2D344F"),
                tick = Color.parseColor("#697497"),
                centerLabelInk = Color.parseColor("#2D344F"),
                centerLabelSurface = Color.parseColor("#E9DEFF"),
            ),
            medium = MediumSkin(
                background = R.drawable.widget_medium_bg_penguin,
                badgeBackground = R.drawable.widget_badge_bg_penguin,
                mascot = R.drawable.widget_penguin,
                featuredMascot = true,
                decor = MediumDecor.SNOWWALK,
                title = Color.parseColor("#2D344F"),
                muted = Color.parseColor("#697497"),
                accent = Color.parseColor("#6577C7"),
            ),
            variant = VariantSkin(
                style = VariantStyle.SNOWWALK,
                pet = R.drawable.widget_variant_penguin,
                timelinePet = RectF(464f, 20f, 633f, 188f),
                cardsPet = RectF(49f, 49f, 207f, 205f),
                badgeFill = Color.parseColor("#6577C7"),
            ),
        )

        /** 기본 팩. 모르는 팩 ID(옛 앱이 남긴 값 등)도 이것으로 그린다. */
        val default: RoutineWidgetSkin get() = starlightCat

        fun forPack(packId: String?): RoutineWidgetSkin = when (packId) {
            "cat_starlight" -> starlightCat
            "poodle_garden" -> poodleGarden
            "cat_stargazer" -> stargazerCat
            "rabbit_postman" -> postmanRabbit
            "squirrel_explorer" -> explorerSquirrel
            "sheep_mooncloud" -> mooncloudSheep
            "redpanda_teashop" -> redPandaTeashop
            "otter_seaside" -> otterSeaside
            "penguin_snow_walk" -> penguinSnowWalk
            else -> starlightCat
        }
    }
}
