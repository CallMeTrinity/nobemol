# Nobémol

Application Android pour apprendre et réviser le solfège. Voir [IDEA.md](IDEA.md) pour le produit et les décisions techniques.

## Structure du repo

```
nobemol/
├── IDEA.md               produit et décisions techniques
├── ROADMAP.md            étapes et avancement
├── nobemol-*.svg         identité visuelle
├── .github/workflows/    CI (un workflow par projet)
└── nobemol-app/          appli Flutter + moteur de notation (voir son README)
```

Un futur back-office Symfony viendrait à côté de `nobemol-app/`, avec son propre workflow.
