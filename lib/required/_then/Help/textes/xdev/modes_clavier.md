## Les modes clavier

Les modes clavier permettent de se servir plus efficacement du clavier. Pour le moment, ils n'ont été implémentés que pour le mode “chiffres simples” qui permet, dans certains contextes, d'utiliser les touches de “q” à “m” (ligne médiane) pour obtenir les chiffres de 0 à 9.

Par exemple, dès que l'application détecte un certain texte de commande (par exemple `ins ` avec l'espace à la fin), elle bascule dans le mode “chiffres simples”. On peut alors taper le chiffre 123 à l'aide de “q s d”. En ajoutant une espace après les chiffres, on revient au mode normal.

Ces modes clavier sont définis dans le module `interact.rb` (qu'on peut facilement atteindre en tapant `CMD T - "inter…"`).
