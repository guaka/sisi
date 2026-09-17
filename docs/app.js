async function loadPacks() {
  const root = document.getElementById("packs");
  try {
    const response = await fetch("packs.json");
    if (!response.ok) throw new Error("Failed to load packs.json");
    const data = await response.json();
    root.innerHTML = "";
    for (const pack of data.packs || []) {
      const article = document.createElement("article");
      article.className = "pack";

      const title = document.createElement("h3");
      title.textContent = pack.title;
      article.appendChild(title);

      const description = document.createElement("p");
      description.textContent = pack.description;
      article.appendChild(description);

      const list = document.createElement("ul");
      list.className = "members";
      for (const member of pack.members || []) {
        const item = document.createElement("li");
        const name = document.createElement("span");
        name.textContent = member.name;
        const id = document.createElement("code");
        id.textContent = member.identifier;
        item.appendChild(name);
        item.appendChild(id);
        list.appendChild(item);
      }
      article.appendChild(list);
      root.appendChild(article);
    }
  } catch (error) {
    root.textContent = "Could not load follow packs.";
    console.error(error);
  }
}

loadPacks();
