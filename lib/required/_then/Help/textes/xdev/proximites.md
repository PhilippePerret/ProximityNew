## Les Proximités

### Recherche des proximités

Si on utilise la base de données pour mettre le panneau courant, on peut utiliser une requête pour trouver rapidement les mots en proximité, de tel sorte qu’il n’est même plus nécessaire de travailler avec la classe `Canon`. Par exemple, c’est cette requête qui permettra d’obtenir le mot recherché :

~~~ruby
stm = db.prepare <<-SQL.freeze
SELECT id
	( offset - ? ) AS distance
	FROM current_page
	WHERE offset > ? AND offset < ?
	ORDER BY distance ASC
	LIMIT 1
SQL

stm = db.bind_param 3, 1210, 1010, 1410
res = stm.execute
row = res.next
# => [ID du text-items] ou [] si aucune proximité
~~~
