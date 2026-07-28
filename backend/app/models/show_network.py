from sqlalchemy import Column, ForeignKey, Table, Uuid

from app.db.base import Base


show_networks = Table(
    "show_networks",
    Base.metadata,
    Column(
        "show_id",
        Uuid(as_uuid=True),
        ForeignKey(
            "shows.id",
            ondelete="CASCADE",
        ),
        primary_key=True,
    ),
    Column(
        "network_id",
        Uuid(as_uuid=True),
        ForeignKey(
            "networks.id",
            ondelete="CASCADE",
        ),
        primary_key=True,
    ),
)