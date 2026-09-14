# Haze : corrections proposées après étude de Glur, VariableBlur et ProgressiveBlur

## Sources lues

- **haze** : `../haze/shaders/haze.frag` (254 lignes) et `../haze/lib/src/haze.dart`
- **Glur** (joogps) :
  - `Sources/Glur/Resources/blur.metal` et `noise.metal`
  - `GlurMask.swift`, `GlurModifier.swift`
  - `GlurBackdrop/BackdropBlurFilter.swift`
- **VariableBlur** (nikstar) : `VariableBlur.swift`, `BackgroundBlur.swift`
- **ProgressiveBlur** (evgen-designer) : `ContentView.swift`. C'est une copie quasi identique de
  VariableBlur (même crédit, jtrivedi/VariableBlurView). Il n'apporte rien de plus.

---

## 1. Ce que font les trois dépôts

| | Glur | VariableBlur / ProgressiveBlur | Haze |
|---|---|---|---|
| Moteur | Shader Metal via `layerEffect` SwiftUI | `CAFilter` privé `variableBlur` sur le `CABackdropLayer` d'un `UIVisualEffectView` | Fragment shader Impeller via `ImageFilter.shader` |
| Rayon par pixel | `mask.alpha * radius` | `mask.alpha * inputRadius` | `sigma * profile(edgeDist)^blurCurve` |
| Forme | Texture de masque (linéaire, radiale, n'importe quelle vue) | Gradient linéaire CI 100×100 | Profil analytique : plateau + smootherstep |
| Bords | `clamp` des positions (répète le pixel du bord) | `inputNormalizeEdges = true` (renormalise) | Renormalise uniquement sur le bord « collé » |
| Nombre de taps | `ceil(3r)`, plafonné à 31 par côté | Pyramide interne de CA (coût constant) | `ceil(3σ)`, plafonné à 64 puis stride > 1 |
| Anti-banding | Bruit « overlay » ×0.1 suivant le masque | Aucun | Dither ±0.5 code, sur l'alpha du scrim seulement |
| Teinte | Aucune | Supprimée (`subview.alpha = 0`) | Scrim adaptatif mesuré |
| Résolution du backdrop | n/a | `backdropLayer.scale = displayScale` (sinon pixelisé en 1×) | Pleine résolution |

**Constat.** Sur la *forme* de la courbe, Haze est déjà plus rigoureux que les trois autres :
- les dérivées sont continues au démarrage et à l'extinction ;
- le plateau est mesuré sur l'effet système ;
- le scrim est adaptatif.

Glur et VariableBlur utilisent une rampe *linéaire*, avec une cassure de pente aux deux
bouts. Il ne faut pas copier leur courbe.

Ce que ces dépôts font mieux, c'est la **plomberie du rendu** : alpha, dither, échantillonnage
et découplage de la forme. Les corrections ci-dessous portent sur ces points.

---

## 2. Corrections, par ordre d'impact

### C1 — Bug : le scrim casse l'alpha prémultiplié (bande pâle au-dessus des vues natives)

`haze.frag:129` :

```glsl
return vec4(mix(c.rgb, u_tint.rgb, clamp(alpha, 0.0, 1.0)), c.a);
```

Le backdrop et la sortie d'un shader Flutter sont **prémultipliés** (`painting.dart:6042`).
`mix` sur `rgb` en gardant `c.a` n'est correct que si `c.a == 1`. Or au-dessus d'un platform
view, Flutter dessine dans un `FlutterOverlayView` vidé en transparent
(`FlutterPlatformViewsController.mm:897`, `Clear(kTransparent)`). Là, `c = (0,0,0,0)` :

- **Résultat actuel :** `rgb = tint·α` avec `a = 0`. C'est un pixel invalide (rgb > a), que
  Core Animation compose en *additif*. En mode clair, on obtient un voile blanc qui éclaircit
  la vue native. En mode sombre, rien du tout (noir additif = 0). Le scrim n'assombrit donc
  jamais un contrôle natif.
- **Résultat attendu :** un « source-over » de la teinte. Le contrôle natif est alors
  réellement couvert, comme le reste de la page.

Même problème en amont : la distance de luminance `d` (ligne 120) est calculée sur des
couleurs prémultipliées. Un pixel semi-transparent paraît plus sombre qu'il ne l'est.

```glsl
vec4 tinted(vec4 c, float profile, vec2 xy) {
  if (u_tint.a <= 0.0 || profile <= 0.0) return c;
  vec3 straight = c.a > 0.0 ? c.rgb / c.a : vec3(0.0);          // dé-prémultiplier
  float d = abs(dot(straight, LUMA) - dot(u_tint.rgb, LUMA));
  float adaptive = 1.0 - TINT_K * pow(d, TINT_P);
  float alpha = clamp(mix(1.0, adaptive, clamp(u_tint_adapt, 0.0, 1.0))
                      * u_tint.a * profile, 0.0, 1.0);
  return c * (1.0 - alpha) + vec4(u_tint.rgb, 1.0) * alpha;      // source-over prémultiplié
}
```

Sur une page opaque (`c.a = 1`), le résultat est identique au bit près à l'actuel. Ça ne
change donc rien là où l'effet est déjà validé.

Au-dessus d'une zone transparente, le scrim dépose maintenant `α` de couverture. C'est
exactement la moitié de l'effet qui manquait sur les contrôles natifs. Ça rend peut-être
inutile une partie du travail de `bar_snapshots.dart` *pour la teinte*. Pour le **flou**, rien
ne change, voir le rapport de compositing.

> À vérifier visuellement en premier : c'est le seul point de la liste qui change un rendu
> existant, et seulement au-dessus des vues natives.

### C2 — Dither sur la couleur finale, pas seulement sur l'alpha du scrim (repris de Glur)

Glur applique `noise.metal` à la couleur finale, avec la même intensité que le masque. Haze
ne dither que l'alpha du scrim (ligne 127). Deux zones restent donc quantifiées :

- **le flou lui-même.** Un grand dégradé flouté (ciel, photo) sort en 8 bits et fait des
  bandes de Mach, surtout en mode sombre, où les pas de code sont les plus visibles ;
- **là où le profil du scrim est nul** (`return c` en tête de `tinted`), qui n'a aucun dither.

La correction consiste à retirer le dither de `tinted` et à l'appliquer une seule fois, en fin
de `main`, pondéré par le profil pour que les pixels hors effet restent intacts :

```glsl
float n = (hash12(xy) - 0.5) / 255.0 * step(1.0e-3, max(blurFalloff, falloff));
frag_color = vec4(clamp(result.rgb + n * result.a, 0.0, result.a), result.a);
```

**Ne pas** reprendre le « grain » visible de Glur (overlay ×0.1, cellules de 10 px). L'effet de
bord iOS 26 n'en a pas. Seul un dither sous le code 8 bits est souhaitable.

### C3 — Aliasing quand la stride dépasse 1 (scintillement au scroll)

Lignes 213–216 : au-delà de 64 taps, `stride = radius / 64` saute des texels. Avec la valeur
par défaut du *package* (`sigma: 12` pt × 3 dpr = 36 px, donc rayon 108 px), la stride vaut
1,7. Du contenu fin qui défile, du texte par exemple, scintille, parce que la phase des texels
sautés change à chaque frame.

`CupertinoScrollEdgeEffect` n'est pas touché (sigma 1,8 pt, soit un rayon de 17 px). En
revanche, tout usage direct de `Haze` avec son défaut l'est.

Deux options, la plus simple en premier :

1. **Plafonner comme Glur** : `kMaxHalfWidth`, et documenter que les grands sigmas perdent
   leur queue. C'est une ligne. Mais Glur plafonne justement parce qu'il ne sait pas faire
   mieux.
2. **Échantillonnage bilinéaire en paires** : chaque tap lit entre deux texels, à l'offset
   `i + w₂/(w₁+w₂)` avec le poids `w₁+w₂`. Chaque tap couvre 2 texels, donc on atteint
   128 texels sans rien sauter. Il faut que le sampler du backdrop soit en filtrage linéaire.
   **À confirmer** sur un cas test (un damier 1 px sous l'effet) avant de l'adopter.

Recommandation : l'option 2 si le damier est lisse, sinon l'option 1.

### C4 — Supprimer la copie périmée `cupertino_widgets/shaders/haze.frag`

Ce projet embarque encore l'ancien shader (107 lignes, falloff cosinus, uniformes 0–11), déclaré
dans `pubspec.yaml:36`. Le shader réel vit dans `../haze`, avec 20 uniformes et une disposition
différente. Or `haze.dart` retombe sur `'shaders/haze.frag'` si l'asset du package échoue. Il
chargerait alors ce fichier avec une disposition d'uniformes incompatible (tint dans
`u_extent`, etc.), sans erreur visible. Rien d'autre ne le référence.

Correction : supprimer le fichier et sa ligne dans `pubspec.yaml`. Dans `haze.dart`, retirer le
second `fromAsset` de secours, car un shader d'une autre version est pire que le fallback en
tranches.

### C5 — Le fallback en tranches mérite mieux (repris de la logique VariableBlur)

`_SlicesFallback` est affiché avant que le shader se charge, et en permanence sans Impeller. Il
a trois défauts :

- **`sliceSize + 0.5`** : les tranches se chevauchent d'un demi-point. Chaque chevauchement
  est flouté deux fois, et on voit une ligne plus floue tous les 1/8.
- **Pas de plateau distinct** : il reçoit `plateau` (celui du scrim), pas `blurPlateau`.
  Son flou ne correspond donc pas à celui du shader.
- **8 tranches** : trop peu pour une rampe douce.

Correction :

- positionner les tranches bord à bord, arrondies aux pixels physiques ;
- passer `blurPlateau` ;
- 12 tranches.

C'est aussi, à 3 lignes près, la variante « bandes » proposée dans le rapport de compositing
comme seule voie qui atteigne les vues natives. Autant qu'elle soit juste.

### C6 — (Optionnel) Découpler la forme du shader, à la Glur

Glur passe un **masque en texture** : le shader lit `mask.a` et ignore d'où vient la forme. On
obtient radial, angulaire ou n'importe quelle vue sans toucher au Metal. Pour Haze,
l'équivalent serait un `ui.Image` 1×256 passé en `setImageSampler(1, …)` et évalué par
`profile()` côté Dart.

Pour l'instant, **ce n'est pas utile**. Il n'y a qu'un seul consommateur (le bord de scroll,
sur quatre côtés), et le profil analytique est plus précis qu'une texture de 256 texels
interpolée linéairement, qui réintroduirait les cassures de dérivée que C1–C5 évitent. À faire
le jour où une forme non directionnelle est demandée.

---

## 3. Ce qu'il ne faut PAS reprendre

- **La rampe linéaire** de VariableBlur et Glur, y compris le `startOffset` négatif. Elle crée
  une cassure de pente au démarrage et à l'extinction. Le profil smootherstep de Haze existe
  précisément pour l'éviter.
- **`CAFilter variableBlur` / `CABackdropLayer`** comme remplaçant : c'est l'approche déjà
  rejetée (vue native faite main + masque). Voir la mémoire *scroll-edge-effect-dead-ends*.
- **Le grain de Glur** : il n'existe pas dans l'effet système (voir C2).
- **`clamp_to_edge` de Glur** sur les bords : il étire le pixel du bord. Le renormalisation
  unilatérale de Haze est déjà plus juste.

## 4. Ordre de mise en œuvre proposé

1. **C4** : suppression, sans risque.
2. **C1** : correctif d'alpha, à valider au-dessus d'un switch natif en clair et en sombre.
3. **C2** : dither.
4. **C5** : fallback.
5. **C3** : après le test du damier.

C1 à C4 tiennent en une trentaine de lignes de GLSL et de Dart. Aucune nouvelle dépendance,
aucun code natif.
