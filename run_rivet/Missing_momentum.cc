// -*- C++ -*-
#include "Rivet/Analysis.hh"
#include "Rivet/Tools/BinnedHistogram.hh"
#include "Rivet/Projections/ChargedFinalState.hh"
#include "Rivet/Projections/VisibleFinalState.hh"

#include "Rivet/Projections/FinalState.hh"
#include "Rivet/Projections/MissingMomentum.hh"

#include "Rivet/Projections/IdentifiedFinalState.hh"
#include "Rivet/Projections/VetoedFinalState.hh"
#include "Rivet/Projections/FastJets.hh"

namespace Rivet {


	class Missing_momentum : public Analysis {
		public:

			/// Constructor
			Missing_momentum()
				: Analysis("Missing_momentum")
			{    }


			/// @name Analysis methods
			//@{

			/// Book histograms and initialize projections before the run
			void init() {
				// projection to find the electrons
				IdentifiedFinalState elecs(Cuts::abseta < 2.47 && Cuts::pT > 20*GeV);
				elecs.acceptIdPair(PID::ELECTRON);
				addProjection(elecs, "elecs");

				// projection to find the muons
				IdentifiedFinalState muons(Cuts::abseta < 2.4 && Cuts::pT > 10*GeV);
				muons.acceptIdPair(PID::MUON);
				addProjection(muons, "muons");

				// Jet finder
				VetoedFinalState vfs;
				addProjection(FastJets(vfs, FastJets::ANTIKT, 0.4), "AntiKtJets04");

				// for pTmiss
				addProjection(VisibleFinalState(Cuts::abseta < 4.9), "vfs");
				addProjection(FinalState(Cuts::abseta < 4.9), "fs");

				// all tracks (to do deltaR with leptons)
				declare(ChargedFinalState(Cuts::abseta < 3 && Cuts::pT > 0.5*GeV), "cfs");

				// *****************************************************************************
				// for etmiss
				const FinalState fs(-4.0, 4.0, 10*GeV);
				MissingMomentum missing(fs);
				addProjection(missing, "MET");

				// jets 
				addProjection(FastJets(fs, FastJets::ANTIKT, 0.4), "Jets");


				// Book histograms
				_hist_ETmiss  = bookHisto1D("ETmiss", 20 , 0. , 1000.);
				_hist_met		  = bookHisto1D("met",		20,  0.	,	1000.);
				_hist_pt_lep  = bookHisto1D("pt_lep", 20,  0., 400.);
				_hist_n_jet   = bookHisto1D("n-jet", 21, -0.5, 20.5);
				_hist_phi_jet = bookHisto1D("phi-jet", 50, -PI, PI);
				_hist_eta_jet = bookHisto1D("eta-jet", 50, -4, 4);
				_hist_pt_jet  = bookHisto1D("pt-jet", 100, 0.0, 1000);
				_hist_dR_x0_j = bookHisto1D("dR-x0-jet", 20, 0.0, 4.0);
			}

			/// Perform the per-event analysis
			void analyze(const Event& event) {
				const double weight = event.weight();

				// pTmiss
				FourMomentum pTmiss;
				foreach (const Particle& p, applyProjection<VisibleFinalState>(event, "vfs").particles() ) {
					pTmiss -= p.momentum();
				}
				double ETmiss = pTmiss.pT();
				// require eTmiss > 150
				//if (ETmiss < 150*GeV) vetoEvent;

				// Calculate and fill missing Et histos
				const MissingMomentum& met = applyProjection<MissingMomentum>(event, "MET");

				// Get jets and fill jet histos
				const FastJets& jetpro = applyProjection<FastJets>(event, "Jets");
				const Jets jets = jetpro.jetsByPt();
				MSG_DEBUG("Jet multiplicity = " << jets.size());
				_hist_n_jet->fill(jets.size(), weight);

				_hist_phi_jet->fill(mapAngleMPiToPi(jets[0].momentum().phi()), weight);
				foreach (const Jet& j, jets) {
					const FourMomentum& pj = j.momentum();
					_hist_eta_jet->fill(pj.eta(), weight);
					_hist_pt_jet->fill(pj.pT()/GeV, weight);
				}

				// distance between x0 and the hardest jet
				foreach (const Particle& p, applyProjection<FinalState>(event, "fs").particles()){
					if (p.pdgId() == 50000){
						double dR = deltaR(p, jets[0]);
						_hist_dR_x0_j->fill(dR, weight);
					}
				}

				Particles chg_tracks = apply<ChargedFinalState>(event, "cfs").particles();
				// TODO combine jet isolation and track-matching in one loop and muons?
				Particles cand_e = apply<IdentifiedFinalState>(event, "elecs").particlesByPt();
				Particles recon_leptons;
				foreach (const Particle &e, cand_e){
					// track isolation:
					double pTinCone = -e.pT();
					foreach (const Particle &track, chg_tracks ){
						if ( deltaR(e.momentum(), track.momentum()) < 0.2 )
							pTinCone += track.pT();
					}
					if (pTinCone < 0.1*e.perp() )
						recon_leptons.push_back(e);
				}

				// Reconstructed Muons
				Particles cand_mu = apply<IdentifiedFinalState>(event,"muons").particlesByPt();
				foreach ( const Particle & mu, cand_mu ) {
					// isolation
					double pTinCone = -mu.pT();
					foreach ( const Particle & track, chg_tracks ) {
						if ( deltaR(mu.momentum(),track.momentum()) < 0.2 )
							pTinCone += track.pT();
					}
					if ( pTinCone < 1.8*GeV )
						recon_leptons.push_back(mu);
				}


				// get the candidate jets
				Jets cand_jets;
				foreach ( const Jet& jet, applyProjection<FastJets>(event, "AntiKtJets04").jetsByPt(30.0*GeV) ) {
					if (jet.abseta() < 4.5) cand_jets.push_back(jet);
				}

				// find the electrons
				Particles cand_es;
				foreach( const Particle& e, applyProjection<IdentifiedFinalState>(event, "elecs").particlesByPt()) {
					// remove any leptons within 0.4 of any candidate jets
					bool e_near_jet = false;
					foreach ( const Jet& jet, cand_jets ) {
						double dR = deltaR(e, jet);
						if (inRange(dR, 0.2, 0.4)) {
							e_near_jet = true;
							break;
						}
					}
					if ( e_near_jet ) continue;
					cand_es.push_back(e);
				}
				// find the muons
				Particles cand_mus;
				foreach( const Particle& mu, applyProjection<IdentifiedFinalState>(event, "muons").particlesByPt()) {
					// remove any leptons within 0.4 of any candidate jets
					bool mu_near_jet = false;
					foreach ( const Jet& jet, cand_jets ) {
						if ( deltaR(mu, jet) < 0.4 ) {
							mu_near_jet = true;
							break;
						}
					}
					if ( mu_near_jet ) continue;
					cand_mus.push_back(mu);
				}

				// discard jets that overlap with electrons
				Jets recon_jets;
				foreach ( const Jet& jet, cand_jets ) {
					if (jet.abseta() > 2.8 || jet.pT() < 30*GeV) continue;
					bool away_from_e = true;
					foreach (const Particle& e, cand_es ) {
						if ( deltaR(e, jet) < 0.2 ) {
							away_from_e = false;
							break;
						}
					}
					if ( away_from_e ) recon_jets.push_back( jet );
				}

				// remove events with tau like jets
				for (unsigned int ix=3;ix<recon_jets.size();++ix) {
					// skip jets seperated from eTmiss
					if (deltaPhi(recon_jets[ix].momentum(),pTmiss)>=0.2*PI)
						continue;
					// check the number of tracks between 1 and 4
					unsigned int ncharged=0;
					foreach ( const Particle & particle, recon_jets[ix].particles()) {
						if (PID::threeCharge(particle.pid())!=0) ++ncharged;
					}
					if (ncharged==0 || ncharged>4) continue;
					// calculate transverse mass and reject if < 100
					double mT = 2.*recon_jets[ix].perp()*ETmiss
						-recon_jets[ix].px()*pTmiss.px()
						-recon_jets[ix].py()*pTmiss.py();
					if (mT<100.) continue; //vetoEvent;
				}

				_hist_ETmiss->fill(ETmiss/GeV, weight);
				_hist_met->fill(met.vectorEt().mod()/GeV);
				if (recon_leptons.size() > 0)
					_hist_pt_lep->fill(recon_leptons[0].pT(), weight);
			}

			void finalize() {

				double norm = crossSection()/sumOfWeights()/femtobarn;
				norm = 1/sumOfWeights();
				scale(_hist_ETmiss,			norm );
				scale(_hist_met,				norm );
				scale(_hist_pt_lep,			norm );
			}

		private:

			/// @name Histograms
			//@{
			Histo1DPtr _hist_n_jet, _hist_phi_jet, _hist_eta_jet, _hist_pt_jet, _hist_dR_x0_j;

			Histo1DPtr _hist_ETmiss, _hist_met, _hist_pt_lep;
			//@}

	};

	// The hook for the plugin system
	DECLARE_RIVET_PLUGIN(Missing_momentum);

	}
