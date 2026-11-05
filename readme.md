# docfctory

Egyszerű körlevélkészítő

![Gootenberg](img/Gutenberg.png)

A program működéséhez Windows operációs rendszer és a MS Excel és Word alkalmazások megléte szükséges. Tesztelve 64-bites Windows 10 és 11 rendszeren, Office 2016-tal.

## Használat

A körlevélsablonba beilleszteni kívánt adatokat Excel táblázat formájában kell megadnunk. A program azt feltételezi hogy a táblázat első sora fejléc, a többi sor pedig egy-egy dokumentum adatait tartalmazza.

A táblázatnak tartalmaznia kell továbbá egy oszlopot, ami a generált dokumentumok nevét adja meg. A dokumentumok .docx formátumban kerülnek mentésre, a kiterjesztést a fájlnév oszlopnak nem kell tartalmaznia.

Emellett készítenünk kell egy dokumentumsablont, amelyben a beilleszteni kívánt szövegek helyét a táblázat szöveget tartalmazó oszlopának \<\> karakterek közé illesztett betűjelével kell behelyettesítenünk. Ha pl. az N oszlop tartalmát akarjuk beilleszteni a dokumentum egy adott pontján, azt az "\<N\>" token beszúrásával érhetjük el.

Egy oszlop tartalmát több helyre is beszúrhatjuk. A beszúrt szöveg megőrzi a token betűformázását.

## Letöltés

[legutóbbi verzió](https://github.com/csd79/docfctory/releases/latest)

## TODO

* Use wax-app facilities:
  * .state
  * Load control workbook as a data source.
  * ERRORSINK
  * Whatever method PTRAIL is using to insert text into a Word doc.
  * PROGRESS-WINDOW
* General cleanup & update to use the current framework.
* Arrange GUI elements into columns using WG-WINDOW.
* Handle some likely errors with assertions.
