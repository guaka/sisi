/** Turn a catalog identifier into a public profile URL, or null. */
function profileURL(identifier) {
  const id = (identifier || "").trim();
  if (!id) return null;

  if (/^https?:\/\//i.test(id)) return id;

  const mastodon = id.match(/^@([^@]+)@([^@]+)$/);
  if (mastodon) {
    return `https://${mastodon[2]}/@${mastodon[1]}`;
  }

  if (/^npub1[0-9a-z]+$/i.test(id)) {
    return `https://njump.me/${id}`;
  }

  // Bluesky handle: name.bsky.social or custom domain-like handle
  if (/^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$/i.test(id)) {
    return `https://bsky.app/profile/${id}`;
  }

  return null;
}

function appendIdentifier(parent, identifier) {
  const url = profileURL(identifier);
  if (url) {
    const link = document.createElement("a");
    link.href = url;
    link.target = "_blank";
    link.rel = "noopener noreferrer";
    link.className = "member-id";
    const code = document.createElement("code");
    code.textContent = identifier;
    link.appendChild(code);
    parent.appendChild(link);
  } else {
    const code = document.createElement("code");
    code.textContent = identifier;
    parent.appendChild(code);
  }
}

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

      const count = document.createElement("p");
      count.className = "pack-meta";
      count.textContent = `${(pack.members || []).length} accounts · follow in the sisi app`;
      article.appendChild(count);

      const list = document.createElement("ul");
      list.className = "members";
      for (const member of pack.members || []) {
        const item = document.createElement("li");
        const name = document.createElement("span");
        name.textContent = member.name;
        item.appendChild(name);
        appendIdentifier(item, member.identifier);
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
