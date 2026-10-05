# Report template — Français (`--lang fr`)

Loaded by **Step 8** when the report language is French. Follow the template **exactly**;
the language-neutral rules (section order, IDs, sorting, score anchors) live in `SKILL.md`.
Use standard French typography (a space before `:`, `?`, `!`).

## Labels

| Element | Value |
|---|---|
| Verdicts | Solide · Fonctionnel mais fragile · Faussement fonctionnel · Nécessite un travail sérieux |
| Confidence (Rule 5) | Haute · Moyenne · Faible |
| Static mode | Commit `n/a — mode statique` · scores `(estimé, sans exécution)` |
| Mandatory creative item | Recommandation non évidente |
| Clone confirmation (Step 2) | « Je vais cloner `<REPO_URL>` dans un répertoire temporaire pour auditer son code. On continue ? » |
| Next steps (Step 9) | Approfondir · Appliquer un correctif · Modèle d'issue · AI-readiness · Comparaison · Nettoyage |
| Engine wording (Model-Naming) | « le protocole de raisonnement interne », « l'auditeur » |

## Template

```markdown
<veredicto>
# 🔍 Audit : <nom-du-dépôt>

**Verdict :** <Solide | Fonctionnel mais fragile | Faussement fonctionnel | Nécessite un travail sérieux>
<2 à 3 phrases honnêtes qui découlent de la liste priorisée, pas de l'optimisme>

**Qualité : X/10** · **AI-Readiness : X/10** · Commit : `<hash | "n/a — mode statique">` · Stack : <runtime> · Maturité : <prototype/bêta/prod>
</veredicto>

<modelo_superior>
## Un raisonnement plus capable pourrait-il améliorer ce code ?
<Ce qui peut être refactorisé sans risque vs. ce qui exige une décision de conception humaine.
« Plus capable » = capacité d'analyse abstraite, jamais un produit d'IA précis.>
</modelo_superior>

<diagnostico>
## Diagnostic exécutif
- **Dépôt :** <URL ou « N/A — fichier local / mode statique »>
- **Objectif réel :** <ce qu'il fait vs. ce qu'il annonce>
- **Taille et couverture de tests :** <évaluation>
</diagnostico>

<hallazgos>
## Constats priorisés
Ordre fixe : d'abord par sévérité (🔴→🔵), puis, à sévérité égale, par confiance (Haute→Faible).
Attribuez des IDs stables après le tri (F1, F2, …) : le Step 10 s'y réfère.

| ID | Sév | Conf | Constat | Preuve | Impact |
|----|-----|------|---------|--------|--------|
| F1 | 🔴  | Haute | …      | `fichier:ligne` | … |
</hallazgos>

<epistemico>
## Audit épistémique et risques cachés
<Biais du chemin heureux, concurrence, fragilité invisible — avec fichier:ligne exacts>
<Hypothèses ouvertes (R2) : interprétation + test qui la confirmerait ou l'écarterait>
</epistemico>

<recomendaciones>
## Recommandations (7 max., par impact réel)
### ⚡ Quick Wins (forte valeur / faible effort)
1. **QW1 · <Problème>** → <Correctif concret> → `fichier:ligne` → résout <F#>
### 🏗️ Chirurgie majeure (refactorings structurels)
1. **CM1 · <Problème>** → <Correctif concret> → `fichier/module` → résout <F#>
### 💡 Recommandation non évidente (obligatoire)
<Le levier créatif du Step 6 : approche alternative / recadrage / AI-readiness + pourquoi>
</recomendaciones>

<contexto>
## Contexte et évolution
- **Historique des versions / diff entre versions :** zones chaudes, ce qui s'est amélioré, ce qui a régressé.
- **Stack et dépendances :** versions et risques notables.
</contexto>

<limites>
## Limites de l'analyse
<Ce qui a été vérifié, ce qui ne l'a pas été, les zones échantillonnées, les hypothèses en
suspens, les priors/hypothèses déclarés, les axes R1 à couverture partielle. En cas de
délégation (Step 3.5), indiquez les axes/chemins délégués et le **model-usage log** (quelle
partie a tourné sur quel modèle et pourquoi : valeur / blocage / redirection / quota). En
mode statique, indiquez quelles étapes dynamiques ont été omises.>
</limites>

<nota_etica>
---
*Rapport élaboré avec l'assistance de l'IA. Nécessite une revue humaine avant d'agir sur
ses conclusions.*
</nota_etica>
```

## Exemple de référence (forme uniquement — ne pas copier son contenu)

```markdown
<veredicto>
# 🔍 Audit : acme-mcp-server
**Verdict :** Fonctionnel mais fragile
Il démarre et répond, mais il mélange les entrées externes avec les instructions internes et
ne contrôle pas le rate limiting. Solide dans sa structure, fragile à ses frontières de confiance.
**Qualité : 6/10** · **AI-Readiness : 5/10** · Commit : `a1b2c3d` · Stack : Node 20 · Maturité : bêta
</veredicto>
... (sections intermédiaires) ...
<hallazgos>
| ID | Sév | Conf | Constat | Preuve | Impact |
|----|-----|------|---------|--------|--------|
| F1 | 🔴 | Haute | Injection de prompt : entrée utilisateur concaténée au system prompt | `src/handler.ts:42` | Une entrée hostile redirige l'agent |
</hallazgos>
```
