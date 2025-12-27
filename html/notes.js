// ============================================
// SYSTÈME DE NOTES EMPLOYÉS
// ============================================

// Charger les notes de l'entreprise
function loadCompanyNotes() {
    postData('getCompanyNotes', {});
}

window.receiveCompanyNotes = function(notes) {
    displayNotesOnDashboard(notes);
    displayNotesInAdmin(notes);
};

// Afficher les notes sur le dashboard (max 3)
function displayNotesOnDashboard(notes) {
    const container = document.getElementById('companyNotesContainer');
    if (!container) return;

    if (!notes || notes.length === 0) {
        container.innerHTML = '';
        return;
    }

    let html = '<div style="margin-top: 20px;"><h3 style="color: #e2e8f0; margin-bottom: 15px; font-size: 16px;"><i class="fa-solid fa-sticky-note"></i> Notes de l\'Entreprise</h3>';

    notes.slice(0, 3).forEach(note => {
        const date = new Date(note.created_at).toLocaleDateString('fr-FR');
        html += `
            <div style="background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%); border: 1px solid #334155; border-left: 4px solid #3b82f6; border-radius: 8px; padding: 15px; margin-bottom: 12px;">
                <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 8px;">
                    <h4 style="color: #3b82f6; margin: 0; font-size: 15px;">${escapeHtml(note.title)}</h4>
                    <span style="color: #64748b; font-size: 11px;">${date}</span>
                </div>
                <p style="color: #cbd5e1; margin: 0; font-size: 13px; line-height: 1.5;">${escapeHtml(note.content)}</p>
                <div style="color: #64748b; font-size: 11px; margin-top: 8px;">
                    <i class="fa-solid fa-user"></i> ${escapeHtml(note.created_by)}
                </div>
            </div>
        `;
    });

    html += '</div>';
    container.innerHTML = html;
}

// Afficher les notes dans l'onglet Administration
function displayNotesInAdmin(notes) {
    const container = document.getElementById('notesList');
    if (!container) return;

    if (!notes || notes.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📝</div><div class="empty-state-text">Aucune note</div></div>';
        return;
    }

    let html = '';
    notes.forEach(note => {
        const date = new Date(note.created_at).toLocaleDateString('fr-FR', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
        html += `
            <div style="background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%); border: 1px solid #334155; border-radius: 8px; padding: 15px; margin-bottom: 12px;">
                <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 10px;">
                    <div style="flex: 1;">
                        <h4 style="color: #3b82f6; margin: 0 0 5px 0; font-size: 16px;">${escapeHtml(note.title)}</h4>
                        <p style="color: #cbd5e1; margin: 0; font-size: 14px; line-height: 1.6;">${escapeHtml(note.content)}</p>
                    </div>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 10px; padding-top: 10px; border-top: 1px solid #334155;">
                    <div style="color: #64748b; font-size: 12px;">
                        <i class="fa-solid fa-user"></i> ${escapeHtml(note.created_by)} • ${date}
                    </div>
                    <div style="display: flex; gap: 8px;">
                        <button onclick="editNote(${note.id}, '${escapeHtml(note.title).replace(/'/g, "\\'")}', '${escapeHtml(note.content).replace(/'/g, "\\'")})"
                                style="background: #3b82f6; border: none; color: white; padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 12px;">
                            <i class="fa-solid fa-edit"></i> Modifier
                        </button>
                        <button onclick="deleteNote(${note.id})"
                                style="background: #dc2626; border: none; color: white; padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 12px;">
                            <i class="fa-solid fa-trash"></i> Supprimer
                        </button>
                    </div>
                </div>
            </div>
        `;
    });

    container.innerHTML = html;
}

// Ajouter une note
document.addEventListener('DOMContentLoaded', () => {
    const addNoteBtn = document.getElementById('addNoteBtn');
    if (addNoteBtn) {
        addNoteBtn.addEventListener('click', () => {
            const title = document.getElementById('newNoteTitle').value.trim();
            const content = document.getElementById('newNoteContent').value.trim();

            if (!title || !content) {
                alert('Veuillez remplir le titre et le contenu');
                return;
            }

            postData('addCompanyNote', { title, content });
            document.getElementById('newNoteTitle').value = '';
            document.getElementById('newNoteContent').value = '';
        });
    }
});

// Modifier une note
window.editNote = function(noteId, title, content) {
    // Créer un modal pour éditer
    const newTitle = prompt('Nouveau titre:', title);
    if (newTitle === null) return;

    const newContent = prompt('Nouveau contenu:', content);
    if (newContent === null) return;

    if (!newTitle.trim() || !newContent.trim()) {
        alert('Le titre et le contenu ne peuvent pas être vides');
        return;
    }

    postData('updateCompanyNote', { noteId, title: newTitle, content: newContent });
};

// Supprimer une note
window.deleteNote = function(noteId) {
    if (confirm('Êtes-vous sûr de vouloir supprimer cette note ?')) {
        postData('deleteCompanyNote', { noteId });
    }
};

// Helper pour échapper le HTML
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
