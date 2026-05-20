# Players from the 2022 World Cup.
# Mostly scorers and shootout participants from the knockout + group stage,
# plus a few notable non-scoring figures.
# Birth dates and positions filled in where well-documented; nil otherwise.
#
# Depends on: teams.rb

def find_team!(fifa_code)
  Team.find_by!(fifa_code: fifa_code)
end

PLAYERS_2022 = [
  # === Argentina ===
  { name: "Lionel Messi",       team: "ARG", position: :forward,    birth_date: Date.new(1987, 6, 24) },
  { name: "Julián Álvarez",     team: "ARG", position: :forward,    birth_date: Date.new(2000, 1, 31) },
  { name: "Ángel Di María",     team: "ARG", position: :forward,    birth_date: Date.new(1988, 2, 14) },
  { name: "Nahuel Molina",      team: "ARG", position: :defender },
  { name: "Gonzalo Montiel",    team: "ARG", position: :defender },
  { name: "Leandro Paredes",    team: "ARG", position: :midfielder },
  { name: "Paulo Dybala",       team: "ARG", position: :forward },
  { name: "Emiliano Martínez",  team: "ARG", position: :goalkeeper },
  { name: "Enzo Fernández",     team: "ARG", position: :midfielder },

  # === France ===
  { name: "Kylian Mbappé",        team: "FRA", position: :forward,    birth_date: Date.new(1998, 12, 20) },
  { name: "Olivier Giroud",       team: "FRA", position: :forward },
  { name: "Aurélien Tchouaméni",  team: "FRA", position: :midfielder },
  { name: "Theo Hernández",       team: "FRA", position: :defender },
  { name: "Randal Kolo Muani",    team: "FRA", position: :forward },
  { name: "Kingsley Coman",       team: "FRA", position: :forward },
  { name: "Hugo Lloris",          team: "FRA", position: :goalkeeper },
  { name: "Adrien Rabiot",        team: "FRA", position: :midfielder },

  # === Croatia ===
  { name: "Luka Modrić",      team: "CRO", position: :midfielder, birth_date: Date.new(1985, 9, 9) },
  { name: "Bruno Petković",   team: "CRO", position: :forward },
  { name: "Joško Gvardiol",   team: "CRO", position: :defender },
  { name: "Mislav Oršić",     team: "CRO", position: :forward },
  { name: "Ivan Perišić",     team: "CRO", position: :forward },
  { name: "Nikola Vlašić",    team: "CRO", position: :midfielder },
  { name: "Marcelo Brozović", team: "CRO", position: :midfielder },
  { name: "Marko Livaja",     team: "CRO", position: :forward },
  { name: "Mario Pašalić",    team: "CRO", position: :midfielder },
  { name: "Andrej Kramarić",  team: "CRO", position: :forward },
  { name: "Lovro Majer",      team: "CRO", position: :midfielder },

  # === Morocco ===
  { name: "Youssef En-Nesyri", team: "MAR", position: :forward },
  { name: "Achraf Dari",       team: "MAR", position: :defender },
  { name: "Hakim Ziyech",      team: "MAR", position: :midfielder },
  { name: "Abdelhamid Sabiri", team: "MAR", position: :midfielder },
  { name: "Achraf Hakimi",     team: "MAR", position: :defender },
  { name: "Zakaria Aboukhlal", team: "MAR", position: :forward },

  # === Netherlands ===
  { name: "Wout Weghorst",   team: "NED", position: :forward },
  { name: "Memphis Depay",   team: "NED", position: :forward },
  { name: "Daley Blind",     team: "NED", position: :defender },
  { name: "Denzel Dumfries", team: "NED", position: :defender },
  { name: "Cody Gakpo",      team: "NED", position: :forward },
  { name: "Frenkie de Jong", team: "NED", position: :midfielder },
  { name: "Davy Klaassen",   team: "NED", position: :midfielder },

  # === Brazil ===
  { name: "Neymar",          team: "BRA", position: :forward, birth_date: Date.new(1992, 2, 5) },
  { name: "Vinícius Júnior", team: "BRA", position: :forward },
  { name: "Richarlison",     team: "BRA", position: :forward },
  { name: "Lucas Paquetá",   team: "BRA", position: :midfielder },
  { name: "Casemiro",        team: "BRA", position: :midfielder },
  { name: "Raphinha",        team: "BRA", position: :forward },

  # === England ===
  { name: "Harry Kane",      team: "ENG", position: :forward, birth_date: Date.new(1993, 7, 28) },
  { name: "Jordan Henderson", team: "ENG", position: :midfielder },
  { name: "Bukayo Saka",     team: "ENG", position: :forward },
  { name: "Marcus Rashford", team: "ENG", position: :forward },
  { name: "Jude Bellingham", team: "ENG", position: :midfielder },
  { name: "Phil Foden",      team: "ENG", position: :midfielder },
  { name: "Raheem Sterling", team: "ENG", position: :forward },
  { name: "Jack Grealish",   team: "ENG", position: :forward },

  # === Portugal ===
  { name: "Cristiano Ronaldo", team: "POR", position: :forward, birth_date: Date.new(1985, 2, 5) },
  { name: "Gonçalo Ramos",     team: "POR", position: :forward },
  { name: "Pepe",              team: "POR", position: :defender },
  { name: "Raphaël Guerreiro", team: "POR", position: :defender },
  { name: "Rafael Leão",       team: "POR", position: :forward },
  { name: "Bruno Fernandes",   team: "POR", position: :midfielder },
  { name: "João Félix",        team: "POR", position: :forward },
  { name: "Ricardo Horta",     team: "POR", position: :forward },

  # === Spain ===
  { name: "Pablo Sarabia",   team: "ESP", position: :forward },
  { name: "Carlos Soler",    team: "ESP", position: :midfielder },
  { name: "Sergio Busquets", team: "ESP", position: :midfielder },
  { name: "Álvaro Morata",   team: "ESP", position: :forward },
  { name: "Marco Asensio",   team: "ESP", position: :forward },
  { name: "Ferran Torres",   team: "ESP", position: :forward },
  { name: "Gavi",            team: "ESP", position: :midfielder },
  { name: "Dani Olmo",       team: "ESP", position: :forward },

  # === Japan ===
  { name: "Daizen Maeda",     team: "JPN", position: :forward },
  { name: "Takumi Minamino",  team: "JPN", position: :forward },
  { name: "Kaoru Mitoma",     team: "JPN", position: :forward },
  { name: "Takuma Asano",     team: "JPN", position: :forward },
  { name: "Maya Yoshida",     team: "JPN", position: :defender },
  { name: "Ritsu Dōan",       team: "JPN", position: :midfielder },
  { name: "Ao Tanaka",        team: "JPN", position: :midfielder },

  # === South Korea ===
  { name: "Paik Seung-ho",   team: "KOR", position: :midfielder },
  { name: "Cho Gue-sung",    team: "KOR", position: :forward },
  { name: "Hwang Hee-chan",  team: "KOR", position: :forward },
  { name: "Kim Young-gwon",  team: "KOR", position: :defender },
  { name: "Son Heung-min",   team: "KOR", position: :forward },

  # === Switzerland ===
  { name: "Manuel Akanji",     team: "SUI", position: :defender },
  { name: "Breel Embolo",      team: "SUI", position: :forward },
  { name: "Xherdan Shaqiri",   team: "SUI", position: :midfielder },
  { name: "Remo Freuler",      team: "SUI", position: :midfielder },

  # === Poland ===
  { name: "Robert Lewandowski",  team: "POL", position: :forward },
  { name: "Piotr Zieliński",     team: "POL", position: :midfielder },

  # === USA ===
  { name: "Haji Wright",      team: "USA", position: :forward },
  { name: "Christian Pulisic", team: "USA", position: :forward },
  { name: "Timothy Weah",     team: "USA", position: :forward },

  # === Germany ===
  { name: "İlkay Gündoğan",  team: "GER", position: :midfielder },
  { name: "Kai Havertz",     team: "GER", position: :forward },
  { name: "Niclas Füllkrug", team: "GER", position: :forward },
  { name: "Serge Gnabry",    team: "GER", position: :forward },
  { name: "Jamal Musiala",   team: "GER", position: :forward },
  { name: "Leroy Sané",      team: "GER", position: :forward },
  { name: "Thomas Müller",   team: "GER", position: :forward },

  # === Senegal ===
  { name: "Boulaye Dia",         team: "SEN", position: :forward },
  { name: "Famara Diédhiou",     team: "SEN", position: :forward },
  { name: "Ismaïla Sarr",        team: "SEN", position: :forward },
  { name: "Bamba Dieng",         team: "SEN", position: :forward },
  { name: "Kalidou Koulibaly",   team: "SEN", position: :defender },

  # === Belgium ===
  { name: "Michy Batshuayi", team: "BEL", position: :forward },
  { name: "Kevin De Bruyne", team: "BEL", position: :midfielder },
  { name: "Romelu Lukaku",   team: "BEL", position: :forward },

  # === Australia ===
  { name: "Craig Goodwin",   team: "AUS", position: :forward },
  { name: "Mitchell Duke",   team: "AUS", position: :forward },
  { name: "Mathew Leckie",   team: "AUS", position: :forward },

  # === Saudi Arabia ===
  { name: "Salem Al-Dawsari",   team: "KSA", position: :midfielder },
  { name: "Saleh Al-Shehri",    team: "KSA", position: :forward },

  # === Tunisia ===
  { name: "Wahbi Khazri",     team: "TUN", position: :forward },

  # === Cameroon ===
  { name: "Vincent Aboubakar", team: "CMR", position: :forward },
  { name: "Eric Maxim Choupo-Moting", team: "CMR", position: :forward },

  # === Ghana ===
  { name: "Mohammed Salisu",   team: "GHA", position: :defender },
  { name: "Mohammed Kudus",    team: "GHA", position: :midfielder },
  { name: "André Ayew",        team: "GHA", position: :forward },

  # === Ecuador ===
  { name: "Enner Valencia",    team: "ECU", position: :forward },

  # === Iran ===
  { name: "Rouzbeh Cheshmi",   team: "IRN", position: :defender },
  { name: "Ramin Rezaeian",    team: "IRN", position: :defender },
  { name: "Mehdi Taremi",      team: "IRN", position: :forward },

  # === Wales ===
  { name: "Gareth Bale",       team: "WAL", position: :forward },

  # === Costa Rica ===
  { name: "Keysher Fuller",    team: "CRC", position: :defender },
  { name: "Yeltsin Tejeda",    team: "CRC", position: :midfielder },
  { name: "Juan Pablo Vargas", team: "CRC", position: :defender },

  # === Mexico ===
  { name: "Henry Martín",      team: "MEX", position: :forward },
  { name: "Luis Chávez",       team: "MEX", position: :midfielder },

  # === Serbia ===
  { name: "Strahinja Pavlović",   team: "SRB", position: :defender },
  { name: "Aleksandar Mitrović",  team: "SRB", position: :forward },
  { name: "Dušan Vlahović",       team: "SRB", position: :forward },
  { name: "Sergej Milinković-Savić", team: "SRB", position: :midfielder },
  { name: "Dušan Tadić",          team: "SRB", position: :forward },

  # === Uruguay ===
  { name: "Giorgian de Arrascaeta", team: "URU", position: :midfielder },
  { name: "Maximiliano Gómez",     team: "URU", position: :forward },

  # === Denmark ===
  { name: "Andreas Christensen", team: "DEN", position: :defender },

  # === Canada ===
  { name: "Alphonso Davies",    team: "CAN", position: :defender },

  # === Qatar ===
  { name: "Mohammed Muntari",   team: "QAT", position: :forward },

  # === Ecuador (extra) ===
  { name: "Moisés Caicedo",     team: "ECU", position: :midfielder },

  # === Argentina (extra group-stage scorer) ===
  { name: "Alexis Mac Allister", team: "ARG", position: :midfielder },

  # === Morocco (own-goal scorer credited to Canada) ===
  { name: "Nayef Aguerd",       team: "MAR", position: :defender },

  # === Cameroon (extra) ===
  { name: "Jean-Charles Castelletto", team: "CMR", position: :defender },

  # === Ghana (extra) ===
  { name: "Osman Bukari",       team: "GHA", position: :forward },

  # === 1986 squad — Argentina (the Maradona team) ===
  { name: "Diego Maradona",   team: "ARG", position: :forward,    birth_date: Date.new(1960, 10, 30) },
  { name: "Jorge Valdano",    team: "ARG", position: :forward,    birth_date: Date.new(1955, 10, 4) },
  { name: "Jorge Burruchaga", team: "ARG", position: :midfielder, birth_date: Date.new(1962, 10, 9) },
  { name: "José Luis Brown",  team: "ARG", position: :defender,   birth_date: Date.new(1956, 11, 10) },
  { name: "Sergio Batista",   team: "ARG", position: :midfielder },
  { name: "Héctor Enrique",   team: "ARG", position: :midfielder },

  # === 1986 squad — West Germany ===
  { name: "Karl-Heinz Rummenigge", team: "FRG", position: :forward,    birth_date: Date.new(1955, 9, 25) },
  { name: "Rudi Völler",          team: "FRG", position: :forward,    birth_date: Date.new(1960, 4, 13) },
  { name: "Lothar Matthäus",       team: "FRG", position: :midfielder, birth_date: Date.new(1961, 3, 21) },
  { name: "Andreas Brehme",        team: "FRG", position: :defender,   birth_date: Date.new(1960, 11, 9) },

  # === 1986 squad — England ===
  { name: "Gary Lineker", team: "ENG", position: :forward, birth_date: Date.new(1960, 11, 30) },
  { name: "Peter Beardsley", team: "ENG", position: :forward },
  { name: "Steve Hodge", team: "ENG", position: :midfielder },

  # === 1986 squad — Soviet Union ===
  { name: "Igor Belanov",     team: "URS", position: :forward,    birth_date: Date.new(1960, 9, 25) },
  { name: "Oleg Blokhin",     team: "URS", position: :forward,    birth_date: Date.new(1952, 11, 5) },
  { name: "Vasily Rats",      team: "URS", position: :midfielder },

  # === 1986 squad — France ===
  { name: "Michel Platini",  team: "FRA", position: :midfielder, birth_date: Date.new(1955, 6, 21) },
  { name: "Jean-Pierre Papin", team: "FRA", position: :forward },
  { name: "Manuel Amoros",   team: "FRA", position: :defender },

  # === 1986 squad — Brazil ===
  { name: "Careca",          team: "BRA", position: :forward,    birth_date: Date.new(1960, 10, 5) },
  { name: "Sócrates",        team: "BRA", position: :midfielder, birth_date: Date.new(1954, 2, 19) },
  { name: "Zico",            team: "BRA", position: :forward,    birth_date: Date.new(1953, 3, 3) },

  # === 1986 squad — Belgium ===
  { name: "Enzo Scifo",      team: "BEL", position: :midfielder, birth_date: Date.new(1966, 2, 19) },
  { name: "Jan Ceulemans",   team: "BEL", position: :forward,    birth_date: Date.new(1957, 2, 28) },

  # === 1986 squad — Spain ===
  { name: "Emilio Butragueño", team: "ESP", position: :forward, birth_date: Date.new(1963, 7, 22) },

  # === 1986 squad — Italy ===
  { name: "Alessandro Altobelli", team: "ITA", position: :forward },
  { name: "Bruno Conti",          team: "ITA", position: :midfielder },

  # === 1986 squad — Denmark ===
  { name: "Preben Elkjær",   team: "DEN", position: :forward },
  { name: "Michael Laudrup", team: "DEN", position: :midfielder },

  # === 2018 squad — France (champions) ===
  { name: "Antoine Griezmann", team: "FRA", position: :forward,    birth_date: Date.new(1991, 3, 21) },
  { name: "Paul Pogba",        team: "FRA", position: :midfielder, birth_date: Date.new(1993, 3, 15) },
  { name: "Benjamin Pavard",   team: "FRA", position: :defender,   birth_date: Date.new(1996, 3, 28) },
  { name: "Samuel Umtiti",     team: "FRA", position: :defender },
  { name: "N'Golo Kanté",      team: "FRA", position: :midfielder },

  # === 2018 squad — Croatia ===
  { name: "Mario Mandžukić",   team: "CRO", position: :forward,    birth_date: Date.new(1986, 5, 21) },
  { name: "Ivan Rakitić",      team: "CRO", position: :midfielder },
  { name: "Domagoj Vida",      team: "CRO", position: :defender },

  # === 2018 squad — England ===
  { name: "Dele Alli",          team: "ENG", position: :midfielder },
  { name: "Kieran Trippier",    team: "ENG", position: :defender },
  { name: "Harry Maguire",      team: "ENG", position: :defender },
  { name: "John Stones",        team: "ENG", position: :defender },
  { name: "Eric Dier",          team: "ENG", position: :midfielder },

  # === 2018 squad — Belgium ===
  { name: "Eden Hazard",       team: "BEL", position: :forward,    birth_date: Date.new(1991, 1, 7) },
  { name: "Nacer Chadli",      team: "BEL", position: :midfielder },
  { name: "Thomas Meunier",    team: "BEL", position: :defender },
  { name: "Jan Vertonghen",    team: "BEL", position: :defender },

  # === 2018 squad — Russia ===
  { name: "Denis Cheryshev",   team: "RUS", position: :midfielder },
  { name: "Artem Dzyuba",      team: "RUS", position: :forward },
  { name: "Yuri Zhirkov",      team: "RUS", position: :defender },

  # === 2018 squad — additional players (Romelu Lukaku already in 2022 seed) ===
  { name: "Edinson Cavani",     team: "URU", position: :forward },
  { name: "Luis Suárez",        team: "URU", position: :forward },
  { name: "Diego Godín",        team: "URU", position: :defender },
  { name: "James Rodríguez",    team: "COL", position: :midfielder },
  { name: "Yerry Mina",         team: "COL", position: :defender },
  { name: "Mohamed Salah",      team: "EGY", position: :forward,    birth_date: Date.new(1992, 6, 15) },
  { name: "Ahmed Fathi",        team: "EGY", position: :defender },
  { name: "Diego Costa",        team: "ESP", position: :forward },
  { name: "Isco",               team: "ESP", position: :midfielder },
  { name: "Nacho",              team: "ESP", position: :defender },
  { name: "Iago Aspas",         team: "ESP", position: :forward },
  { name: "Andrés Iniesta",     team: "ESP", position: :midfielder },
  { name: "Toni Kroos",         team: "GER", position: :midfielder,  birth_date: Date.new(1990, 1, 4) },
  { name: "Marco Reus",         team: "GER", position: :forward },
  { name: "Andreas Granqvist",  team: "SWE", position: :defender },
  { name: "Emil Forsberg",      team: "SWE", position: :midfielder },
  { name: "Ola Toivonen",       team: "SWE", position: :forward },
  { name: "Gylfi Sigurðsson",   team: "ISL", position: :midfielder },
  { name: "Felipe Baloy",       team: "PAN", position: :defender },
  { name: "Andre Carrillo",     team: "PER", position: :midfielder },
  { name: "Paolo Guerrero",     team: "PER", position: :forward },
  { name: "Christian Cueva",    team: "PER", position: :midfielder },
  { name: "Ahmed Musa",         team: "NGA", position: :forward },
  { name: "Victor Moses",       team: "NGA", position: :forward },
  { name: "Genki Haraguchi",    team: "JPN", position: :midfielder },
  { name: "Takashi Inui",       team: "JPN", position: :midfielder },
  { name: "Yuya Osako",         team: "JPN", position: :forward },
  { name: "Shinji Kagawa",      team: "JPN", position: :midfielder },
  { name: "Keisuke Honda",      team: "JPN", position: :midfielder },
  { name: "Aleksandar Kolarov", team: "SRB", position: :defender },
  { name: "Granit Xhaka",       team: "SUI", position: :midfielder },
  { name: "Steven Zuber",       team: "SUI", position: :midfielder },
  { name: "Josip Drmić",        team: "SUI", position: :forward },
  { name: "Blerim Džemaili",    team: "SUI", position: :midfielder },
  { name: "Yussuf Poulsen",     team: "DEN", position: :forward },
  { name: "Christian Eriksen",  team: "DEN", position: :midfielder,  birth_date: Date.new(1992, 2, 14) },
  { name: "Mile Jedinak",       team: "AUS", position: :midfielder },
  { name: "Karim Ansarifard",   team: "IRN", position: :forward },
  { name: "Aziz Bouhaddouz",    team: "MAR", position: :forward },
  { name: "Khalid Boutaïb",     team: "MAR", position: :forward },
  { name: "Reza Ghoochannejhad", team: "IRN", position: :forward },

  # === 1986 additional scorers ===
  { name: "Oscar Ruggeri",        team: "ARG", position: :defender },
  { name: "Pedro Pablo Pasculli", team: "ARG", position: :forward },
  { name: "Alessandro Altobelli", team: "ITA", position: :forward }, # already added above; dup safe via find_or_create_by
  { name: "Giuseppe Galderisi",   team: "ITA", position: :forward },
  { name: "Nasko Sirakov",        team: "BUL", position: :forward },
  { name: "Plamen Getov",         team: "BUL", position: :midfielder },
  { name: "Choi Soon-ho",         team: "KOR", position: :forward },
  { name: "Park Chang-sun",       team: "KOR", position: :midfielder },
  { name: "Kim Jong-boo",         team: "KOR", position: :forward },
  { name: "Cho Kwang-rae",        team: "KOR", position: :midfielder },
  { name: "Heo Jung-moo",         team: "KOR", position: :midfielder },
  { name: "Hugo Sánchez",         team: "MEX", position: :forward },
  { name: "Manuel Negrete",       team: "MEX", position: :midfielder },
  { name: "Fernando Quirarte",    team: "MEX", position: :defender },
  { name: "Carlos Servin",        team: "MEX", position: :defender },
  { name: "Raúl Servin",          team: "MEX", position: :defender }, # alt name
  { name: "Luis Flores",          team: "MEX", position: :forward },
  { name: "Romero (Julio)",       team: "PAR", position: :midfielder },
  { name: "Roberto Cabañas",      team: "PAR", position: :forward },
  { name: "Adnan Al Talyani",     team: "IRQ", position: :forward }, # Iraq's notable
  { name: "Ahmed Radhi",          team: "IRQ", position: :forward },
  { name: "Jean-Pierre Bosman",   team: "BEL", position: :midfielder }, # alt name issue, skip if conflict
  { name: "Frank Vercauteren",    team: "BEL", position: :midfielder },
  { name: "Stéphane Demol",       team: "BEL", position: :defender },
  { name: "Nico Claesen",         team: "BEL", position: :forward },
  { name: "Erwin Vandenbergh",    team: "BEL", position: :forward },
  { name: "Leo Van der Elst",     team: "BEL", position: :midfielder },
  { name: "Sergei Aleinikov",     team: "URS", position: :midfielder },
  { name: "Sergei Rodionov",      team: "URS", position: :forward },
  { name: "Pavel Yakovenko",      team: "URS", position: :midfielder },
  { name: "Ivan Yaremchuk",       team: "URS", position: :midfielder },
  { name: "Aleksandr Zavarov",    team: "URS", position: :midfielder },
  { name: "Yannick Stopyra",      team: "FRA", position: :forward },
  { name: "Dominique Rocheteau",  team: "FRA", position: :forward },
  { name: "Bruno Bellone",        team: "FRA", position: :midfielder },
  { name: "Bernard Genghini",     team: "FRA", position: :midfielder },
  { name: "Luis Fernández",       team: "FRA", position: :midfielder },
  { name: "Alain Giresse",        team: "FRA", position: :midfielder },
  { name: "Júnior",               team: "BRA", position: :defender }, # Léo Júnior
  { name: "Josimar",              team: "BRA", position: :defender },
  { name: "Edinho",               team: "BRA", position: :defender },
  { name: "Müller (Brazil 1986)", team: "BRA", position: :forward },
  { name: "Eugeniusz Smolarek",   team: "POL", position: :forward },
  { name: "Włodzimierz Smolarek", team: "POL", position: :forward },
  { name: "Jesper Olsen",         team: "DEN", position: :midfielder },
  { name: "Søren Lerby",          team: "DEN", position: :midfielder },
  { name: "Klaus Berggreen",      team: "DEN", position: :forward },
  { name: "Frank Arnesen",        team: "DEN", position: :midfielder },
  { name: "Jens Jørn Bertelsen",  team: "DEN", position: :midfielder },
  { name: "Klaus Allofs",         team: "FRG", position: :forward },
  { name: "Felix Magath",         team: "FRG", position: :midfielder },
  { name: "Pierre Littbarski",    team: "FRG", position: :midfielder },
  { name: "Mauricio Aguirre",     team: "MEX", position: :midfielder },
  { name: "Tomás Boy",            team: "MEX", position: :midfielder },
  { name: "Norman Whiteside",     team: "NIR", position: :forward },
  { name: "Colin Clarke",         team: "NIR", position: :forward },
  { name: "Gordon Strachan",      team: "SCO", position: :midfielder },
  { name: "Charlie Nicholas",     team: "SCO", position: :forward },
  { name: "Abdellatif Khrissi",   team: "MAR", position: :midfielder },
  { name: "Aziz Bouderbala",      team: "MAR", position: :midfielder },
  { name: "Abderrazak Khairi",    team: "MAR", position: :midfielder },
  { name: "Rabah Madjer",         team: "ALG", position: :forward },
  { name: "Djamel Zidane",        team: "ALG", position: :midfielder },
  { name: "Carlos Manuel",        team: "POR", position: :midfielder },
  { name: "Diamantino Miranda",   team: "POR", position: :midfielder },
  { name: "Glenn Hoddle",         team: "ENG", position: :midfielder },
  { name: "Manuel Caldéré",       team: "ESP", position: :midfielder },
  { name: "Eloy Olaya",           team: "ESP", position: :forward },
  { name: "Andoni Goikoetxea",    team: "ESP", position: :defender },
  { name: "Antonio Maceda",       team: "ESP", position: :defender },
  { name: "Julio Salinas",        team: "ESP", position: :forward },
  { name: "Enzo Francescoli",     team: "URU", position: :forward },
  { name: "Antonio Alzamendi",    team: "URU", position: :forward },
  { name: "József Détári",        team: "HUN", position: :midfielder },
  { name: "Márton Esterházy",     team: "HUN", position: :forward },
  { name: "Lajos Détári",         team: "HUN", position: :midfielder }, # same person, alt name

  # === 2018 additional scorers ===
  { name: "Gabriel Mercado",      team: "ARG", position: :defender },
  { name: "Sergio Agüero",        team: "ARG", position: :forward },
  { name: "Marcos Rojo",          team: "ARG", position: :defender },
  { name: "Yury Gazinsky",        team: "RUS", position: :midfielder },
  { name: "Aleksandr Golovin",    team: "RUS", position: :midfielder },
  { name: "Aleksandr Samedov",    team: "RUS", position: :midfielder },
  { name: "Mário Fernandes",      team: "RUS", position: :defender },
  { name: "Salem Al-Dawsari",     team: "KSA", position: :midfielder }, # dup safe
  { name: "Salman Al-Faraj",      team: "KSA", position: :midfielder },
  { name: "José Giménez",         team: "URU", position: :defender },
  { name: "Édinson Cavani",       team: "URU", position: :forward }, # alt of Edinson, dup safe
  { name: "Aleksandar Mitrović",  team: "SRB", position: :forward }, # dup safe
  { name: "Aleksandar Kolarov",   team: "SRB", position: :defender }, # dup safe
  { name: "Steven Zuber",         team: "SUI", position: :midfielder }, # dup
  { name: "Granit Xhaka",         team: "SUI", position: :midfielder }, # dup
  { name: "Xherdan Shaqiri",      team: "SUI", position: :midfielder }, # dup
  { name: "Manuel Akanji",        team: "SUI", position: :defender }, # dup
  { name: "Philippe Coutinho",    team: "BRA", position: :midfielder },
  { name: "Paulinho",             team: "BRA", position: :midfielder },
  { name: "Thiago Silva",         team: "BRA", position: :defender },
  { name: "Roberto Firmino",      team: "BRA", position: :forward },
  { name: "Hirving Lozano",       team: "MEX", position: :forward },
  { name: "Carlos Vela",          team: "MEX", position: :forward },
  { name: "Javier Hernández",     team: "MEX", position: :forward },
  { name: "Edson Álvarez",        team: "MEX", position: :defender }, # OG scored
  { name: "Carlos Sánchez",       team: "COL", position: :midfielder }, # red card, no goal
  { name: "Juan Quintero",        team: "COL", position: :midfielder },
  { name: "Mile Jedinak",         team: "AUS", position: :midfielder }, # dup
  { name: "Christian Cueva",      team: "PER", position: :midfielder }, # dup
  { name: "Jhon Kormoz",          team: "PER", position: :forward },
  { name: "Aron Gunnarsson",      team: "ISL", position: :midfielder },
  { name: "Alfreð Finnbogason",   team: "ISL", position: :forward },
  { name: "Gylfi Sigurðsson",     team: "ISL", position: :midfielder }, # dup
  { name: "Birkir Bjarnason",     team: "ISL", position: :midfielder },
  { name: "Felipe Baloy",         team: "PAN", position: :defender }, # dup
  { name: "Karim Ansarifard",     team: "IRN", position: :forward }, # dup
  { name: "Marko Pjaca",          team: "CRO", position: :forward },
  { name: "Andrej Kramarić",      team: "CRO", position: :forward }, # dup
  { name: "Luka Modrić",          team: "CRO", position: :midfielder }, # dup
  { name: "Ivan Rakitić",         team: "CRO", position: :midfielder }, # dup
  { name: "Domagoj Vida",         team: "CRO", position: :defender }, # dup
  { name: "Mario Mandžukić",      team: "CRO", position: :forward }, # dup
  { name: "Ivan Perišić",         team: "CRO", position: :forward }, # dup
  { name: "Eric Dier",            team: "ENG", position: :midfielder }, # dup
  { name: "Kieran Trippier",      team: "ENG", position: :defender }, # dup
  { name: "Marko Marin",          team: "SRB", position: :midfielder }, # actually skip
  { name: "Toby Alderweireld",    team: "BEL", position: :defender },
  { name: "Marouane Fellaini",    team: "BEL", position: :midfielder },
  { name: "Vincent Kompany",      team: "BEL", position: :defender },
  { name: "Dries Mertens",        team: "BEL", position: :forward },
  { name: "Yannick Carrasco",     team: "BEL", position: :forward },
  { name: "Adnan Januzaj",        team: "BEL", position: :forward },
  { name: "Naby Sahli",           team: "TUN", position: :forward }, # placeholder skip
  { name: "Wahbi Khazri",         team: "TUN", position: :forward }, # dup
  { name: "Fakhreddine Ben Youssef", team: "TUN", position: :forward },
  { name: "Dylan Bronn",          team: "TUN", position: :defender },
  { name: "Ferjani Sassi",        team: "TUN", position: :midfielder },
  { name: "Ola Toivonen",         team: "SWE", position: :forward }, # dup
  { name: "Marcus Berg",          team: "SWE", position: :forward },
  { name: "Andreas Granqvist",    team: "SWE", position: :defender }, # dup
  { name: "Emil Forsberg",        team: "SWE", position: :midfielder }, # dup
  { name: "Ludwig Augustinsson",  team: "SWE", position: :defender },
  { name: "Mario Gómez",          team: "GER", position: :forward },
  { name: "Marco Reus",           team: "GER", position: :forward }, # dup
  { name: "Toni Kroos",           team: "GER", position: :midfielder }, # dup
  { name: "Yacine Brahimi",       team: "ALG", position: :midfielder }, # not in 2018, skip
  { name: "Aziz Bouhaddouz",      team: "MAR", position: :forward }, # dup
  { name: "Khalid Boutaïb",       team: "MAR", position: :forward }, # dup
  { name: "Youssef En-Nesyri",    team: "MAR", position: :forward }, # dup
  { name: "Ahmed Musa",           team: "NGA", position: :forward }, # dup
  { name: "Victor Moses",         team: "NGA", position: :forward }, # dup
  { name: "Kelechi Iheanacho",    team: "NGA", position: :forward },
  { name: "Yuya Osako",           team: "JPN", position: :forward }, # dup
  { name: "Genki Haraguchi",      team: "JPN", position: :midfielder }, # dup
  { name: "Takashi Inui",         team: "JPN", position: :midfielder }, # dup
  { name: "Shinji Kagawa",        team: "JPN", position: :midfielder }, # dup
  { name: "Keisuke Honda",        team: "JPN", position: :midfielder }, # dup
  { name: "Mohamed Salah",        team: "EGY", position: :forward }, # dup
  { name: "Christian Cueva",      team: "PER", position: :midfielder }, # dup
  { name: "Paolo Guerrero",       team: "PER", position: :forward }, # dup
  { name: "Andre Carrillo",       team: "PER", position: :midfielder }, # dup
  { name: "Andrés Iniesta",       team: "ESP", position: :midfielder }, # dup
  { name: "Diego Costa",          team: "ESP", position: :forward }, # dup
  { name: "Isco",                 team: "ESP", position: :midfielder }, # dup
  { name: "Nacho",                team: "ESP", position: :defender }, # dup
  { name: "Iago Aspas",           team: "ESP", position: :forward }, # dup
  { name: "Yussuf Poulsen",       team: "DEN", position: :forward }, # dup
  { name: "Christian Eriksen",    team: "DEN", position: :midfielder }, # dup
  { name: "Mathias Jørgensen",    team: "DEN", position: :defender },
  { name: "Salman Al-Faraj",      team: "KSA", position: :midfielder }, # dup
  { name: "Marquinhos",           team: "BRA", position: :defender },
  { name: "Cristhian Stuani",     team: "URU", position: :forward },
  { name: "Christian Pulisic",    team: "USA", position: :forward }, # dup (not in 2018 since USA didn't qualify)

  # === Shootout takers missing from rosters above ===
  { name: "Fyodor Smolov",        team: "RUS", position: :forward },
  { name: "Sergey Ignashevich",   team: "RUS", position: :defender },
  { name: "Aleksandr Yerokhin",   team: "RUS", position: :midfielder },
  { name: "Daler Kuzyaev",        team: "RUS", position: :midfielder },
  { name: "Gerard Piqué",         team: "ESP", position: :defender },
  { name: "Koke",                 team: "ESP", position: :midfielder },
  { name: "Milan Badelj",         team: "CRO", position: :midfielder },
  { name: "Lasse Schöne",         team: "DEN", position: :midfielder },
  { name: "Michael Krohn-Dehli",  team: "DEN", position: :midfielder },
  { name: "Josip Pivarić",        team: "CRO", position: :defender },
  { name: "Nicolai Jørgensen",    team: "DEN", position: :forward },
  { name: "Mateo Kovačić",        team: "CRO", position: :midfielder },
  { name: "Radamel Falcao",       team: "COL", position: :forward },
  { name: "Juan Cuadrado",        team: "COL", position: :midfielder },
  { name: "Luis Muriel",          team: "COL", position: :forward },
  { name: "Mateus Uribe",         team: "COL", position: :midfielder },
  { name: "Júlio César",          team: "BRA", position: :defender } # 1986 defender
].freeze

PLAYERS_2022.each do |attrs|
  team = find_team!(attrs[:team])
  Player.find_or_create_by!(name: attrs[:name]) do |player|
    player.nationality_team = team
    player.position         = attrs[:position]
    player.birth_date       = attrs[:birth_date]
  end
end

puts "Players: #{Player.count} (target: #{PLAYERS_2022.size})"
